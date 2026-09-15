import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';
import 'package:satellite_view/widgets/custom_location_permission_handler.dart';

import '../../../core/utils/constants.dart';
import 'route_polyline_segments.dart';

class RouteFinderProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isLiveTracking = false;

  /// Whether location permission is granted.
  /// Used by the UI to decide whether to show the blue dot / location button.
  bool hasLocationPermission = false;

  Timer? _livePulseTimer;
  bool _livePulseVisible = true;

  String _wrongDestination = '';
  String get wrongDestination => _wrongDestination;

  /// CONTROLLERS
  TextEditingController sourceController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  /// MAP CONTROLLER
  GoogleMapController? mapController;

  /// MARKERS
  Set<Marker> markers = {};
  BitmapDescriptor? customSourceMarker;
  BitmapDescriptor? customLiveMarker;

  /// POLYLINES
  Set<Polyline> polylines = {};

  /// POLYLINE POINTS
  List<LatLng> polylineCoordinates = [];

  /// API KEY
  final String googleApiKey = Constants.mapKey;

  /// SOURCE LAT LNG
  LatLng? sourceLatLng;
  bool sourceWasAutoLocation = false;

  /// DESTINATION LAT LNG
  LatLng? destinationLatLng;

  final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _livePositionSubscription;
  LatLng? _lastTrackedLatLng;
  LatLng? _lastCameraTarget;
  DateTime? _lastCameraUpdatedAt;
  bool _isRefreshingRoute = false;
  bool isRerouting = false;
  double? currentHeading;
  double? currentGpsAccuracyMeters;
  double? currentSpeedMetersPerSecond;
  int? totalDistanceMeters;
  int? totalDurationSeconds;
  int? remainingDistanceMeters;
  DateTime? _lastRouteRefreshAt;
  LatLng? _lastRouteRefreshPoint;
  DateTime? _lastDeviationDetectedAt;
  double _smoothedSpeedMps = 0;
  double? currentRouteDeviationMeters;
  bool isOffRoute = false;

  String get routeDistanceLabel {
    if (totalDistanceMeters == null) return 'Distance —';
    final meters = totalDistanceMeters!.toDouble();
    if (meters >= 1000) {
      final kilometers = meters / 1000;
      final precision = kilometers >= 10 ? 0 : 1;
      return '${kilometers.toStringAsFixed(precision)} km';
    }
    return '${meters.round()} m';
  }

  String get remainingDistanceLabel {
    if (remainingDistanceMeters == null) return 'Remaining —';
    if (remainingDistanceMeters! >= 1000) {
      final kilometers = remainingDistanceMeters! / 1000;
      final precision = kilometers >= 10 ? 0 : 1;
      return '${kilometers.toStringAsFixed(precision)} km remaining';
    }
    return '${remainingDistanceMeters!.round()} m remaining';
  }

  String get routeEtaLabel {
    if (remainingDistanceMeters == null) {
      _wrongDestination = 'Enter wrong destination location.\nPlease try again';
      return 'Arrival —';
    }
    final estimatedSeconds = _calculateEtaSeconds();
    if (estimatedSeconds <= 0) return 'Arriving now';
    if (estimatedSeconds < 60) return 'Arriving now';
    if (estimatedSeconds < 3600) {
      return '~${(estimatedSeconds / 60).round()} min';
    }
    final hours = estimatedSeconds ~/ 3600;
    final minutes = ((estimatedSeconds % 3600) / 60).round();
    return '~$hours hr $minutes min';
  }

  double get routeProgressValue {
    if (totalDistanceMeters == null ||
        totalDistanceMeters == 0 ||
        remainingDistanceMeters == null) {
      return 0;
    }
    return (1 - (remainingDistanceMeters! / totalDistanceMeters!)).clamp(0, 1);
  }

  String get liveStatusLabel {
    if (isLoading) return 'Planning route';
    if (isRerouting) return 'Recalculating route';
    if (isOffRoute) return 'Off route';
    if (isLiveTracking) return 'Live tracking';
    if (destinationLatLng != null && polylines.isNotEmpty) return 'Route ready';
    return 'Waiting for route';
  }

  Color get liveStatusColor {
    if (isLoading || isRerouting || isOffRoute) return Colors.orange;
    if (isLiveTracking) return Colors.green;
    if (destinationLatLng != null && polylines.isNotEmpty) {
      return CustomColors.primaryColor;
    }
    return Colors.grey;
  }

  bool get isLowGpsConfidence {
    return currentGpsAccuracyMeters != null &&
        currentGpsAccuracyMeters! > 30;
  }

  String get gpsConfidenceLabel {
    if (currentGpsAccuracyMeters == null) return 'GPS syncing';
    if (isLowGpsConfidence) return 'Low GPS confidence';
    if (currentGpsAccuracyMeters! <= 10) return 'High confidence';
    return 'Good confidence';
  }

  Color get gpsConfidenceColor {
    if (isLowGpsConfidence) return Colors.orange;
    if (currentGpsAccuracyMeters == null) return Colors.grey;
    return Colors.green;
  }

  double get liveFollowZoom {
    if (_smoothedSpeedMps >= 8) return 15.2;
    if (_smoothedSpeedMps >= 3) return 15.8;
    return 16.4;
  }

  String get etaConfidenceLabel {
    if (!isLiveTracking) return 'Route ETA';
    if (currentGpsAccuracyMeters == null) return 'Syncing ETA';
    if (currentGpsAccuracyMeters! > 30) return 'Approx ETA';
    if (_smoothedSpeedMps >= 2) return 'Live ETA';
    return 'Balanced ETA';
  }

  Color get etaConfidenceColor {
    if (!isLiveTracking) return Colors.white;
    if (currentGpsAccuracyMeters == null) return Colors.grey;
    if (currentGpsAccuracyMeters! > 30 || _smoothedSpeedMps < 2) {
      return Colors.orange.shade200;
    }
    return Colors.green.shade200;
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _updateNavigationMetrics() {
    if (sourceLatLng == null ||
        destinationLatLng == null ||
        polylineCoordinates.length < 2 ||
        totalDistanceMeters == null ||
        totalDurationSeconds == null) {
      remainingDistanceMeters = totalDistanceMeters;
      return;
    }

    final traveledDistance = _projectedDistanceAlongRoute(sourceLatLng!);
    final routedDistance = totalDistanceMeters!.toDouble();

    if (traveledDistance == null || routedDistance <= 0) {
      remainingDistanceMeters = totalDistanceMeters;
      return;
    }

    final remaining = math.max(0, routedDistance - traveledDistance);
    remainingDistanceMeters = remaining.round();
  }

  double? _projectedDistanceAlongRoute(LatLng currentLocation) {
    if (polylineCoordinates.length < 2) return null;

    double cumulativeDistance = 0;
    double bestProjectedDistance = 0;
    double bestDistance = double.infinity;

    for (int index = 0; index < polylineCoordinates.length - 1; index++) {
      final start = polylineCoordinates[index];
      final end = polylineCoordinates[index + 1];
      final segmentLength = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      final segmentProjection = _segmentProjection(currentLocation, start, end);
      if (segmentProjection.distance < bestDistance) {
        bestDistance = segmentProjection.distance;
        bestProjectedDistance =
            cumulativeDistance + segmentProjection.progress * segmentLength;
      }

      cumulativeDistance += segmentLength;
    }

    return bestProjectedDistance;
  }

  ({double distance, double progress}) _segmentProjection(
      LatLng point,
      LatLng start,
      LatLng end,
      ) {
    final latScale = 111320.0;
    final lngScale = 111320.0 *
        math.cos(((start.latitude + end.latitude) * math.pi) / 360);

    final dx = (end.longitude - start.longitude) * lngScale;
    final dy = (end.latitude - start.latitude) * latScale;
    final px = (point.longitude - start.longitude) * lngScale;
    final py = (point.latitude - start.latitude) * latScale;

    final segmentLengthSquared = dx * dx + dy * dy;
    if (segmentLengthSquared == 0) {
      final distance = math.sqrt(px * px + py * py);
      return (distance: distance, progress: 0);
    }

    final progress = (px * dx + py * dy) / segmentLengthSquared;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final projectionX = dx * clampedProgress;
    final projectionY = dy * clampedProgress;
    final distanceX = px - projectionX;
    final distanceY = py - projectionY;
    final distance = math.sqrt(distanceX * distanceX + distanceY * distanceY);

    return (distance: distance, progress: clampedProgress);
  }

  int _estimateRemainingDurationSeconds() {
    if (remainingDistanceMeters == null ||
        totalDistanceMeters == null ||
        totalDurationSeconds == null) {
      return 0;
    }
    if (totalDistanceMeters == 0) return 0;
    final ratio = remainingDistanceMeters! / totalDistanceMeters!;
    return (totalDurationSeconds! * ratio).round();
  }

  int _calculateEtaSeconds() {
    if (remainingDistanceMeters == null || remainingDistanceMeters == 0) {
      return 0;
    }
    final fallbackEstimate = _estimateRemainingDurationSeconds();
    if (!isLiveTracking || _smoothedSpeedMps <= 0.5) return fallbackEstimate;
    final liveEstimate = (remainingDistanceMeters! / _smoothedSpeedMps).round();
    if (fallbackEstimate == 0) return liveEstimate;
    return ((liveEstimate * 0.7) + (fallbackEstimate * 0.3)).round();
  }

  double _currentRouteDeviationMeters(LatLng currentLocation) {
    if (polylineCoordinates.length < 2) return double.infinity;

    double bestDistance = double.infinity;
    for (var index = 0; index < polylineCoordinates.length - 1; index++) {
      final start = polylineCoordinates[index];
      final end = polylineCoordinates[index + 1];
      final projection = _segmentProjection(currentLocation, start, end);
      bestDistance = math.min(bestDistance, projection.distance);
    }
    return bestDistance;
  }

  void _startLivePulse() {
    _livePulseTimer?.cancel();
    _livePulseVisible = true;
    _livePulseTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      _livePulseVisible = !_livePulseVisible;
      notifyListeners();
    });
  }

  void _stopLivePulse() {
    _livePulseTimer?.cancel();
    _livePulseTimer = null;
    _livePulseVisible = true;
  }

  void clearRoute() {
    markers.clear();
    polylines.clear();
    polylineCoordinates.clear();
    sourceLatLng = null;
    destinationLatLng = null;
    customSourceMarker = null;
    customLiveMarker = null;
    totalDistanceMeters = null;
    totalDurationSeconds = null;
    remainingDistanceMeters = null;
    currentHeading = null;
    currentGpsAccuracyMeters = null;
    currentSpeedMetersPerSecond = null;
    _lastRouteRefreshAt = null;
    _lastRouteRefreshPoint = null;
    _lastCameraTarget = null;
    _lastCameraUpdatedAt = null;
    _lastDeviationDetectedAt = null;
    _smoothedSpeedMps = 0;
    currentRouteDeviationMeters = null;
    isOffRoute = false;
    _stopLivePulse();
    isRerouting = false;
    notifyListeners();
  }

  void _syncVisiblePolylines() {
    polylines.clear();
    if (polylineCoordinates.length < 2 || sourceLatLng == null) return;

    final split = splitRoutePolyline(
      routeCoordinates: polylineCoordinates,
      currentLocation: sourceLatLng!,
    );

    if (split.completed.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('completed_route'),
          points: split.completed,
          color: Colors.grey.shade400,
          width: 5,
          geodesic: true,
        ),
      );
    }

    if (split.remaining.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_route'),
          points: split.remaining,
          color: CustomColors.primaryColor,
          width: 6,
          geodesic: true,
        ),
      );
    }
  }

  double _cameraThresholdMeters() {
    if (_smoothedSpeedMps >= 8) return 12;
    if (_smoothedSpeedMps >= 3) return 15;
    return 10;
  }

  bool _shouldAnimateCamera(LatLng updatedLatLng) {
    if (_lastCameraTarget == null) return true;
    final distance = Geolocator.distanceBetween(
      _lastCameraTarget!.latitude,
      _lastCameraTarget!.longitude,
      updatedLatLng.latitude,
      updatedLatLng.longitude,
    );
    if (distance >= _cameraThresholdMeters()) return true;
    final lastUpdatedAt = _lastCameraUpdatedAt;
    if (lastUpdatedAt == null) return true;
    return DateTime.now().difference(lastUpdatedAt) >=
        const Duration(seconds: 3);
  }

  void _updateRouteDeviation(LatLng updatedLatLng) {
    currentRouteDeviationMeters = _currentRouteDeviationMeters(updatedLatLng);
    isOffRoute = currentRouteDeviationMeters != null &&
        currentRouteDeviationMeters! > 30;
  }

  /// Starts live tracking only if permission is granted.
  /// Never throws — if permission is denied, the provider simply stays
  /// in "route ready" mode without live tracking.
  Future<void> startLiveTracking() async {
    if (isLiveTracking) return;

    try {
      final currentPosition =
      sourceLatLng == null
          ? await CustomLocationPermissionHandler.determinePosition()
          : null;

      if (currentPosition == null && sourceLatLng == null) {
        // Permission denied and no source set. Stay functional.
        hasLocationPermission = false;
        notifyListeners();
        return;
      }

      hasLocationPermission = true;

      if (currentPosition != null) {
        sourceLatLng = LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );
        currentGpsAccuracyMeters = currentPosition.accuracy;
        currentSpeedMetersPerSecond = currentPosition.speed;
      }

      if (sourceLatLng == null) return;

      isLiveTracking = true;
      _startLivePulse();
      _lastTrackedLatLng = sourceLatLng;
      _syncSourceMarker();
      _updateNavigationMetrics();

      _livePositionSubscription = geolocatorPlatform
          .getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      )
          .listen(
        _handleLivePositionUpdate,
        onError: (e) {
          debugPrint('Live tracking stream error: $e');
        },
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to start live tracking: $e');
      hasLocationPermission = false;
      notifyListeners();
    }
  }

  Future<void> stopLiveTracking() async {
    await _livePositionSubscription?.cancel();
    _livePositionSubscription = null;
    isLiveTracking = false;
    _stopLivePulse();
    notifyListeners();
  }

  void _updateHeadingFromPosition(Position position) {
    if (!position.heading.isFinite || position.heading < 0) return;
    currentHeading = position.heading;
  }

  Future<void> _refreshRouteIfNeeded(LatLng updatedLatLng) async {
    if (destinationLatLng == null || _isRefreshingRoute) return;

    final now = DateTime.now();
    final lastRefreshAt = _lastRouteRefreshAt;
    final lastRefreshPoint = _lastRouteRefreshPoint;
    final deviationMeters = _currentRouteDeviationMeters(updatedLatLng);
    currentRouteDeviationMeters = deviationMeters;
    isOffRoute = deviationMeters > 30;

    if (deviationMeters > 30) {
      _lastDeviationDetectedAt ??= now;
    } else {
      _lastDeviationDetectedAt = null;
    }

    final distanceSinceRefresh = lastRefreshPoint == null
        ? double.infinity
        : Geolocator.distanceBetween(
      lastRefreshPoint.latitude,
      lastRefreshPoint.longitude,
      updatedLatLng.latitude,
      updatedLatLng.longitude,
    );

    final sustainedDeviation = _lastDeviationDetectedAt != null &&
        now.difference(_lastDeviationDetectedAt!) >= const Duration(seconds: 8);

    final shouldRefresh = lastRefreshAt == null ||
        sustainedDeviation ||
        distanceSinceRefresh >= 60 ||
        now.difference(lastRefreshAt) >= const Duration(seconds: 35);

    if (!shouldRefresh) return;

    _isRefreshingRoute = true;
    isRerouting = true;
    notifyListeners();

    try {
      await getPolyline();
      _lastRouteRefreshAt = now;
      _lastRouteRefreshPoint = updatedLatLng;
    } finally {
      isRerouting = false;
      _isRefreshingRoute = false;
      notifyListeners();
    }
  }

  Future<void> _handleLivePositionUpdate(Position position) async {
    _updateHeadingFromPosition(position);
    currentGpsAccuracyMeters = position.accuracy;
    final speed = position.speed.isFinite && position.speed >= 0
        ? position.speed
        : currentSpeedMetersPerSecond ?? 0;

    currentSpeedMetersPerSecond = speed;
    _smoothedSpeedMps = (_smoothedSpeedMps * 0.7) + (speed * 0.3);

    final updatedLatLng = LatLng(position.latitude, position.longitude);

    if (_lastTrackedLatLng != null) {
      final distance = Geolocator.distanceBetween(
        _lastTrackedLatLng!.latitude,
        _lastTrackedLatLng!.longitude,
        updatedLatLng.latitude,
        updatedLatLng.longitude,
      );
      if (distance < 2) {
        sourceLatLng = updatedLatLng;
        _syncSourceMarker();
        _updateNavigationMetrics();
        notifyListeners();
        return;
      }
    }

    _lastTrackedLatLng = updatedLatLng;
    sourceLatLng = updatedLatLng;

    _updateRouteDeviation(updatedLatLng);
    _syncSourceMarker();
    _syncVisiblePolylines();
    _updateNavigationMetrics();
    await _refreshRouteIfNeeded(updatedLatLng);

    if (_shouldAnimateCamera(updatedLatLng)) {
      _lastCameraTarget = updatedLatLng;
      _lastCameraUpdatedAt = DateTime.now();
      unawaited(
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(updatedLatLng, liveFollowZoom),
        ),
      );
    }

    notifyListeners();
  }

  void _syncSourceMarker() {
    if (sourceLatLng == null) return;

    markers.removeWhere(
          (marker) => marker.markerId == const MarkerId('source'),
    );
    markers.add(
      Marker(
        markerId: const MarkerId('source'),
        position: sourceLatLng!,
        rotation: currentHeading ?? 0,
        icon: isLiveTracking
            ? (customLiveMarker ?? BitmapDescriptor.defaultMarker)
            : (customSourceMarker ?? BitmapDescriptor.defaultMarker),
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: isLiveTracking ? 'Live Tracking' : 'Source',
        ),
      ),
    );
  }

  Future<void> generateRoute({
    BitmapDescriptor? sourceMarker,
    destinationMarker,
    liveMarker,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      clearRoute();

      final sourceText = sourceController.text.trim();
      final destinationText = destinationController.text.trim();

      final validationError = await validateRouteInputs(
        source: sourceText,
        destination: destinationText,
      );

      if (validationError != null) throw Exception(validationError);

      debugPrint("Source LatLng: $sourceLatLng");
      debugPrint("Destination LatLng: $destinationLatLng");

      customSourceMarker = sourceMarker;
      customLiveMarker = liveMarker;
      _syncSourceMarker();

      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destinationLatLng!,
          icon: destinationMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );

      await getPolyline();
      await setCameraBounds();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> validateRouteInputs({
    required String source,
    required String destination,
  }) async {
    if (source.isEmpty) return 'Please enter a source address.';
    if (destination.isEmpty) return 'Please enter a destination address.';

    sourceLatLng = await _resolveLatLngFromInput(
      source,
      sourceLatLng,
      useAutoLocationFallback: sourceWasAutoLocation,
    );

    if (sourceLatLng == null) return 'Please enter a correct source location.';

    destinationLatLng = await _resolveLatLngFromInput(
      destination,
      destinationLatLng,
      useAutoLocationFallback: false,
    );

    if (destinationLatLng == null) {
      return 'Please enter a correct destination location.';
    }

    return null;
  }

  Future<LatLng?> _resolveLatLngFromInput(
      String input,
      LatLng? currentLatLng, {
        required bool useAutoLocationFallback,
      }) async {
    if (useAutoLocationFallback && currentLatLng != null) {
      debugPrint("Using auto current location directly");
      return currentLatLng;
    }

    if (input.isEmpty) return null;

    final parsedLatLng = _parseCoordinateString(input);
    if (parsedLatLng != null) return parsedLatLng;

    try {
      final locations = await locationFromAddress(input);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      debugPrint('Geocoding failed: $e');
    }

    return null;
  }

  LatLng? _parseCoordinateString(String input) {
    final coordinatePattern = RegExp(
      r"([-+]?\d{1,3}(?:\.\d+)?)[,\s]+([-+]?\d{1,3}(?:\.\d+)?)",
    );
    final match = coordinatePattern.firstMatch(input);
    if (match == null) return null;

    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  Future<void> getPolyline() async {
    if (sourceLatLng == null || destinationLatLng == null) return;

    try {
      final polylinePoints = PolylinePoints(apiKey: googleApiKey);

      final routeRequest = PolylineRequest(
        origin: PointLatLng(sourceLatLng!.latitude, sourceLatLng!.longitude),
        destination: PointLatLng(
          destinationLatLng!.latitude,
          destinationLatLng!.longitude,
        ),
        mode: TravelMode.driving,
      );

      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: routeRequest,
      );

      debugPrint("Polyline Status: ${result.status}");
      debugPrint("Polyline Error: ${result.errorMessage}");

      if (result.points.isNotEmpty) {
        totalDistanceMeters = result.totalDistanceValue;
        totalDurationSeconds = result.totalDurationValue;

        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        _syncVisiblePolylines();
        _updateNavigationMetrics();
      } else {
        debugPrint('No polyline points found');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Polyline Error: $e');
    }
  }

  Future<void> setCameraBounds() async {
    if (sourceLatLng == null || destinationLatLng == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        sourceLatLng!.latitude < destinationLatLng!.latitude
            ? sourceLatLng!.latitude
            : destinationLatLng!.latitude,
        sourceLatLng!.longitude < destinationLatLng!.longitude
            ? sourceLatLng!.longitude
            : destinationLatLng!.longitude,
      ),
      northeast: LatLng(
        sourceLatLng!.latitude > destinationLatLng!.latitude
            ? sourceLatLng!.latitude
            : destinationLatLng!.latitude,
        sourceLatLng!.longitude > destinationLatLng!.longitude
            ? sourceLatLng!.longitude
            : destinationLatLng!.longitude,
      ),
    );

    await mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  void dispose() {
    stopLiveTracking();
    super.dispose();
  }
}