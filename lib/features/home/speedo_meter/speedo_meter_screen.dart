import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:satellite_view/local/local_sp.dart';
import 'package:satellite_view/widgets/custom_location_permission_handler.dart';

import '../../../core/theme/custom_colors.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';
import 'speedometer_utils.dart';

class SpeedoMeterScreen extends StatefulWidget
{
    const SpeedoMeterScreen({super.key});

    @override
    State<SpeedoMeterScreen> createState() => _SpeedoMeterScreenState();
}

class _SpeedoMeterScreenState extends State<SpeedoMeterScreen>
{
    static const String _topSpeedHistoryKey = 'speedometer_top_speed_history';
    static const String _routeHistoryKey = 'speedometer_route_history';
    static const double _speedAlertThreshold = 90.0;

    double currentSpeed = 0.0;
    String? errorText;
    DateTime? lastUpdateTime;
    double? accuracyMeters;
    double? altitudeMeters;
    double? headingDegrees;
    bool isPermissionBlocked = false;
    bool _voiceAlertReady = false;
    bool _speedAlertActive = false;
    double _sessionTopSpeed = 0.0;
    List<double> _topSpeedHistory = <double>[];
    List<Map<String, double>> _routePoints = <Map<String, double>>[];
    LatLng? _latestLivePosition;
    GoogleMapController? _mapController;
    StreamSubscription<Position>? _positionSubscription;
    final FlutterTts _flutterTts = FlutterTts();

    @override
    void initState()
    {
        super.initState();
        _loadPersistedAnalytics();
        _initializeVoiceAlerts();
        _startLocationStream();
    }

    Future<void> _startLocationStream() async
    {
        try
        {
            await CustomLocationPermissionHandler.determinePosition();
            _listenToPositionUpdates();
        }
        catch (error)
        {
            _handleLocationError(error);
        }
    }

    void _listenToPositionUpdates()
    {
        _positionSubscription?.cancel();

        _positionSubscription = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 1
            )
        ).listen(_handlePositionUpdate, onError: _handleLocationError);
    }

    void _handlePositionUpdate(Position position)
    {
        if (!mounted)
        {
            return;
        }

        final safeSpeed = clampSpeedValue(
            position.speed >= 0 ? position.speed * 3.6 : 0.0
        );

        _latestLivePosition = LatLng(position.latitude, position.longitude);

        if (safeSpeed > _sessionTopSpeed)
        {
            _sessionTopSpeed = safeSpeed;
        }

        _topSpeedHistory = updateTopSpeedHistory(_topSpeedHistory, safeSpeed);

        _routePoints = <Map<String, double>>[
            ..._routePoints,
            {
                'lat': position.latitude,
                'lng': position.longitude,
            },
        ];

        if (_routePoints.length > 500)
        {
            _routePoints = _routePoints.sublist(_routePoints.length - 500);
        }

        if (safeSpeed >= _speedAlertThreshold && !_speedAlertActive)
        {
            _speedAlertActive = true;
            _announceSpeedAlert();
        }
        else if (safeSpeed < _speedAlertThreshold)
        {
            _speedAlertActive = false;
        }

        setState(()
            {
                currentSpeed = safeSpeed;
                accuracyMeters = position.accuracy;
                altitudeMeters = position.altitude;
                headingDegrees = position.heading >= 0 ? position.heading : null;
                lastUpdateTime = DateTime.now();
                errorText = null;
                isPermissionBlocked = false;
            }
        );

        _updateMapCamera();
        _persistAnalytics();
    }

    void _updateMapCamera()
    {
        if (_mapController == null || _latestLivePosition == null)
        {
            return;
        }

        _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_latestLivePosition!, 14)
        );
    }

    void _handleLocationError(Object error)
    {
        if (!mounted)
        {
            return;
        }

        setState(()
            {
                errorText = error.toString();
                isPermissionBlocked = error.toString().toLowerCase().contains(
                    'permanently'
                );
            }
        );
    }

    Future<void> _openLocationSettings() async
    {
        await Geolocator.openAppSettings();
    }

    Future<void> _initializeVoiceAlerts() async
    {
        try
        {
            await _flutterTts.setLanguage('en-US');
            await _flutterTts.setSpeechRate(0.42);
            await _flutterTts.setVolume(1.0);
            await _flutterTts.setPitch(1.0);
            _voiceAlertReady = true;
        }
        catch (_) {
            _voiceAlertReady = false;
        }
    }

    Future<void> _loadPersistedAnalytics() async
    {
        final savedTopSpeedHistory = decodeTopSpeedHistory(
            LocalSP.getStringData(_topSpeedHistoryKey) as String?
        );

        final savedRoutePoints = LocalSP.getStringData(_routeHistoryKey) as String?;

        if (savedTopSpeedHistory.isNotEmpty)
        {
            _topSpeedHistory = savedTopSpeedHistory;
        }

        if (savedRoutePoints != null && savedRoutePoints.isNotEmpty)
        {
            try
            {
                final decoded = jsonDecode(savedRoutePoints);
                if (decoded is List)
                {
                    _routePoints = decoded
                        .map<Map<String, double>>((entry)
                        {
                            final point = entry as Map<String, dynamic>;
                            return <String, double>{
                                'lat': (point['lat'] as num).toDouble(),
                                'lng': (point['lng'] as num).toDouble(),
                            };
                        })
                        .toList(growable: false);
                }
            }
            catch (_) {}
        }
    }

    Future<void> _persistAnalytics() async
    {
        await LocalSP.setStringData(
            _topSpeedHistoryKey,
            encodeTopSpeedHistory(_topSpeedHistory)
        );

        await LocalSP.setStringData(
            _routeHistoryKey,
            jsonEncode(_routePoints)
        );
    }

    Future<void> _announceSpeedAlert() async
    {
        if (!_voiceAlertReady)
        {
            return;
        }

        try
        {
            await _flutterTts.stop();
            await _flutterTts.speak(
                'Speed alert. Current speed is ${currentSpeed.round()} kilometers per hour.'
            );
        }
        catch (_) {}
    }

    String get _rpmText => rpmLabelForSpeed(currentSpeed);
    String get _gearLabel => gearLabelForSpeed(currentSpeed);
    String get _signalQuality => signalQualityFromAccuracy(accuracyMeters);

    String get _lastUpdatedLabel
    {
        if (lastUpdateTime == null)
        {
            return 'Waiting for live GPS';
        }

        final difference = DateTime.now().difference(lastUpdateTime!);
        if (difference.inSeconds < 1)
        {
            return 'Just now';
        }
        if (difference.inMinutes < 1)
        {
            return '${difference.inSeconds}s ago';
        }
        if (difference.inHours < 1)
        {
            return '${difference.inMinutes}m ago';
        }

        return '${difference.inHours}h ago';
    }

    @override
    void dispose()
    {

        _positionSubscription?.cancel();
        _flutterTts.stop();
        super.dispose();
    }

    @override
    Widget build(BuildContext context)
    {
        final theme = Theme.of(context);

        return SafeArea(
          top: false,
          child: Scaffold(
              backgroundColor: const Color(0xFF06130F),
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                  title: Text(
                      'Speedometer',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5
                      )
                  ),
                  centerTitle: true,
                  backgroundColor: CustomColors.primaryColor,
                  elevation: 0,
                  leading: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: ()
                      {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
                              (route) => false
                          );
                      },
                      child: Container(
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: CustomColors.iconBackgroundColor,
                              shape: BoxShape.circle
                          ),
                          child: const Center(
                              child: Icon(Icons.arrow_back, color: Color(0xFF004226), size: 22)
                          )
                      )
                  )
              ),
              body: Container(
                  decoration:  BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor
                  ),
                  child: SafeArea(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                          child: Column(
                              children: [
                                  if (errorText != null) _buildErrorBanner(),
                                  if (errorText != null) const SizedBox(height: 16),
                                  _buildStatusHeader(),
                                  const SizedBox(height: 18),
                                  Expanded(
                                      child: SingleChildScrollView(
                                          child: Column(
                                              children: [
                                                  _buildGaugeCard(),
                                                  const SizedBox(height: 16),
                                                  _buildLiveMetricsRow(),
                                                  const SizedBox(height: 16),
                                                  _buildInfoCard(),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                      'Live GPS speed is active. Other vehicle telemetry is unavailable without OBD data.',
                                                      textAlign: TextAlign.center,
                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                          height: 1.5
                                                      )
                                                  )
                                              ]
                                          )
                                      )
                                  )
                              ]
                          )
                      )
                  )
              ),
            bottomNavigationBar:BannerAdmob(),

          ),
        );
    }

    Widget _buildErrorBanner()
    {
        return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: CustomColors.error,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7))
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        'GPS connection issue',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        )
                    ),
                    const SizedBox(height: 8),
                    Text(
                        errorText ?? 'Unable to access your location right now.',
                        style: const TextStyle(color: Colors.white70, height: 1.5)
                    ),
                    if (isPermissionBlocked)
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                            onPressed: _openLocationSettings,
                            icon: const Icon(Icons.settings, size: 18, fontWeight: FontWeight.bold,),
                            label: Text('Open settings', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                            ))
                        )
                    )
                ]
            )
        );
    }

    Widget _buildStatusHeader()
    {
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Row(
                    children: [
                        Container(
                            width: 15,
                            height: 15,
                            decoration:  BoxDecoration(
                                color: Colors.green.shade700,
                                shape: BoxShape.circle
                            )
                        ),
                        const SizedBox(width: 8),
                        Text(
                            errorText == null ? 'Live GPS tracking' : 'GPS paused',
                            style:  TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold
                            )
                        )
                    ]
                ),
                Text(
                    _lastUpdatedLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)
                )
            ]
        );
    }

    Widget _buildGaugeCard()
    {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color:  CustomColors.iconBackgroundColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12)
            ),
            child: Column(
                children: [
                    SfRadialGauge(
                        axes: <RadialAxis>[
                            RadialAxis(
                                startAngle: 140,
                                endAngle: 40,
                                minimum: 0,
                                maximum: 240,
                                radiusFactor: 0.95,
                                majorTickStyle:  MajorTickStyle(
                                    length: 12,
                                    thickness: 2,
                                    color: CustomColors.primaryColor
                                ),
                                minorTicksPerInterval: 4,
                                minorTickStyle:  MinorTickStyle(
                                    length: 6,
                                    thickness: 1,
                                    color: CustomColors.primaryColor
                                ),
                                axisLineStyle: const AxisLineStyle(
                                    thickness: 18,
                                    gradient: SweepGradient(
                                        colors: [
                                            Color(0xFF1DE9B6),
                                            Color(0xFFFFEA00),
                                            Color(0xFFFFB300),
                                            Color(0xFFFF5252)
                                        ],
                                        stops: [0.2, 0.45, 0.75, 1]
                                    )
                                ),
                                axisLabelStyle:  GaugeTextStyle(
                                    fontSize: 14,
                                    color: CustomColors.primaryColor
                                ),
                                pointers: <GaugePointer>[
                                    NeedlePointer(
                                        value: currentSpeed,
                                        enableAnimation: true,
                                        animationType: AnimationType.easeOutBack,
                                        needleColor: Colors.white,
                                        needleStartWidth: 1,
                                        needleEndWidth: 5,
                                        needleLength: 0.82,
                                        animationDuration: 1000,
                                        gradient:  LinearGradient(
                                            colors: [CustomColors.error, CustomColors.error, CustomColors.error, CustomColors.error]
                                        ),
                                        knobStyle: KnobStyle(
                                            color:  Colors.white,
                                            knobRadius: 0.12,
                                            borderColor: CustomColors.primaryColor,
                                            borderWidth: 0.05
                                        )
                                    )
                                ],
                                ranges: <GaugeRange>[
                                    GaugeRange(
                                        startValue: 0,
                                        endValue: 30,
                                        color: const Color(0xFF7C4DFF),
                                        startWidth: 18,
                                        endWidth: 18
                                    ),
                                    GaugeRange(
                                        startValue: 30,
                                        endValue: 80,
                                        color: const Color(0xFF1DE9B6),
                                        startWidth: 18,
                                        endWidth: 18
                                    ),
                                    GaugeRange(
                                        startValue: 80,
                                        endValue: 160,
                                        color: const Color(0xFFFFEA00),
                                        startWidth: 18,
                                        endWidth: 18
                                    ),
                                    GaugeRange(
                                        startValue: 160,
                                        endValue: 240,
                                        color: const Color(0xFFFF5252),
                                        startWidth: 18,
                                        endWidth: 18
                                    )
                                ],
                                annotations: [
                                    GaugeAnnotation(
                                        widget: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                Text(
                                                    formatSpeedLabel(currentSpeed),
                                                    style:  TextStyle(
                                                        fontSize: 48,
                                                        fontWeight: FontWeight.bold,
                                                        color: CustomColors.primaryColor,
                                                        shadows: [
                                                            Shadow(color: Colors.white24, blurRadius: 18)
                                                        ]
                                                    )
                                                ),
                                                const Text(
                                                    'km/h',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold
                                                    )
                                                )
                                            ]
                                        ),
                                        angle: 90,
                                        positionFactor: 0.68
                                    )
                                ]
                            )
                        ]
                    ),
                    const SizedBox(height: 12),
                    Text(
                        'Gear $_gearLabel • ${_signalQuality.toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13
                        )
                    )
                ]
            )
        );
    }

    Widget _buildLiveMetricsRow()
    {
        return Row(
            children: [
                Expanded(
                    child: _buildDashboardCard(
                        label: 'RPM',
                        value: _rpmText,
                        color: Colors.green.shade700
                    )
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDashboardCard(
                        label: 'Fuel',
                        value: 'N/A',
                        color: Colors.orangeAccent
                    )
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDashboardCard(
                        label: 'Temp',
                        value: 'N/A',
                        color: Colors.redAccent
                    )
                )
            ]
        );
    }

    Widget _buildInfoCard()
    {
        final accuracyText = accuracyMeters == null
            ? 'Waiting'
            : '${accuracyMeters!.toStringAsFixed(1)} m';
        final altitudeText = altitudeMeters == null
            ? 'Waiting'
            : '${altitudeMeters!.toStringAsFixed(1)} m';
        final headingText = headingDegrees == null
            ? 'Waiting'
            : '${headingDegrees!.toStringAsFixed(0)}°';

        return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: CustomColors.primaryColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12)
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        'Live GPS details',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                        )
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                            _buildDetailChip('Accuracy', accuracyText),
                            _buildDetailChip('Altitude', altitudeText),
                            _buildDetailChip('Heading', headingText),
                            _buildDetailChip('Signal', _signalQuality)
                        ]
                    )
                ]
            )
        );
    }

    Widget _buildDashboardCard({
        required String label,
        required String value,
        required Color color
    })
    {
        return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: CustomColors.iconBackgroundColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.shade700, width: 2)
            ),
            child: Column(
                children: [
                    Text(
                        label,
                        style: TextStyle(
                            fontSize: 13,
                          fontWeight: FontWeight.bold
                        )
                    ),
                    const SizedBox(height: 8),
                    Text(
                        value,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                            shadows: [
                                Shadow(color: color.withValues(alpha: 0.45), blurRadius: 12)
                            ]
                        )
                    )
                ]
            )
        );
    }

    Widget _buildDetailChip(String label, String value)
    {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
                color: CustomColors.iconBackgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4)
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Text(
                        label,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          fontWeight: FontWeight.bold
                        )
                    ),
                    const SizedBox(height: 4),
                    Text(
                        value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold
                        )
                    )
                ]
            )
        );
    }
}
