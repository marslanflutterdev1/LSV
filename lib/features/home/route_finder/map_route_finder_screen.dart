import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/features/home/route_finder/route_finder_provider.dart';
import 'package:satellite_view/features/home/route_finder/route_finder_screen.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import 'package:satellite_view/widgets/custom_cherry_toast.dart';
import 'package:satellite_view/widgets/custom_marker.dart';
import '../../../core/theme/custom_colors.dart';

class MapRouteFinderScreen extends StatefulWidget {
  const MapRouteFinderScreen({super.key});

  @override
  State<MapRouteFinderScreen> createState() => _MapRouteFinderScreenState();
}

class _MapRouteFinderScreenState extends State<MapRouteFinderScreen> {
  late RouteFinderProvider _provider;
  BitmapDescriptor? sourceMarker;
  BitmapDescriptor? destinationMarker;
  BitmapDescriptor? liveMarker;
  Timer? _pulseTimer;
  bool _pulseVisible = true;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<RouteFinderProvider>(context, listen: false);
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() => _pulseVisible = !_pulseVisible);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _setUpCustomMarker();
      if (!mounted) return;

      try {
        await _provider.generateRoute(
          sourceMarker: sourceMarker,
          destinationMarker: destinationMarker,
          liveMarker: liveMarker,
        );
        if (!mounted) return;
        // ✅ Safe to call even if permission is denied.
        await _provider.startLiveTracking();
      } catch (e) {
        if (!mounted) return;
        CustomCherryToast.warning(
          context,
          title: 'Please enter correct source and destination locations.',
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _provider.stopLiveTracking();
    super.dispose();
  }

  Future<void> _setUpCustomMarker() async {
    sourceMarker ??= await CustomMarker.setMarker(
      path: 'assets/images/source_location.png',
      targetWidth: 40,
      targetHeight: 40,
    );
    destinationMarker ??= await CustomMarker.setMarker(
      path: 'assets/images/destination_location.png',
      targetWidth: 40,
      targetHeight: 40,
    );
    liveMarker ??= await CustomMarker.setMarker(
      path: 'assets/images/live.png',
      targetWidth: 40,
      targetHeight: 40,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteFinderProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          top: false,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Map View',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: CustomColors.primaryColor,
              leading: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const RouteFinderScreen()),
                        (r) => false,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CustomColors.iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back,
                      color: CustomColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target:
                      provider.sourceLatLng ?? const LatLng(31.4504, 73.1350),
                      zoom: 18,
                    ),
                    mapType: MapType.normal,
                    // ✅ Conditional — only when permission granted.
                    myLocationEnabled: provider.hasLocationPermission,
                    myLocationButtonEnabled: provider.hasLocationPermission,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    onMapCreated: provider.onMapCreated,
                    markers: provider.markers,
                    polylines: provider.polylines,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: CustomColors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 700),
                            width: provider.isLiveTracking ? 16 : 14,
                            height: provider.isLiveTracking ? 16 : 14,
                            decoration: BoxDecoration(
                              color: provider.liveStatusColor.withValues(
                                alpha: provider.isLiveTracking
                                    ? (_pulseVisible ? 0.28 : 0.12)
                                    : 0.22,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: provider.liveStatusColor,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              provider.liveStatusLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (provider.isLiveTracking)
                            Text(
                              'You are here',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: provider.liveStatusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (provider.isLiveTracking || provider.isRerouting)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                provider.isRerouting
                                    ? Icons.sync
                                    : Icons.navigation,
                                size: 18,
                                fontWeight: FontWeight.bold,
                                color: provider.liveStatusColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // ✅ Small info banner when permission denied (no Settings button)
                  if (!provider.hasLocationPermission)
                    Positioned(
                      top: 60,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: CustomColors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: CustomColors.primaryColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Location access is off. Route is shown, but live tracking is paused until location is enabled in Settings.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (provider.isOffRoute)
                    Positioned(
                      top: 60,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You are off route. Recalculating the best path.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CustomColors.primaryColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated time of arrival',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                              color: CustomColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _RouteMetricTile(
                                icon: Icons.timer_outlined,
                                title: 'Arrival',
                                value: provider.routeEtaLabel,
                              ),
                              Container(
                                width: 4,
                                height: 44,
                                color: Colors.grey.shade200,
                              ),
                              _RouteMetricTile(
                                icon: Icons.straighten_outlined,
                                title: 'Remaining',
                                value: provider.remainingDistanceLabel,
                              ),
                            ],
                          ),
                          if (provider.isLowGpsConfidence) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  provider.gpsConfidenceLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BannerAdmob(),
          ),
        );
      },
    );
  }
}

class _RouteMetricTile extends StatelessWidget {
  const _RouteMetricTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: CustomColors.white,
                  fontWeight: FontWeight.bold),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CustomColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CustomColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}