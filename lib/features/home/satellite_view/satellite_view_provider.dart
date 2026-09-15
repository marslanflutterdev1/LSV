import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:satellite_view/widgets/custom_location_permission_handler.dart';

class SatelliteViewProvider extends ChangeNotifier {
  final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;

  // Default fallback location (e.g., a country center or last known).
  // Change this to a meaningful default for your app.
  static const LatLng _defaultLatLng = LatLng(37.7749, -122.4194);

  LatLng _currentLatLng = _defaultLatLng;
  String _currentAddress = "Location unavailable";
  StreamSubscription<Position>? _positionStream;

  bool _isLocationLoaded = false;   // map is ready to render
  bool _hasLocationPermission = false; // user's live location available

  LatLng get currentLatLng => _currentLatLng;
  String get currentAddress => _currentAddress;
  StreamSubscription<Position>? get positionStream => _positionStream;
  bool get isLocationLoaded => _isLocationLoaded;
  bool get hasLocationPermission => _hasLocationPermission;

  Future<void> getLiveLocationMethod() async {
    // 1. Try to get the user's position (never throws now)
    final Position? position =
    await CustomLocationPermissionHandler.determinePosition();

    if (position == null) {
      // Permission denied or services off.
      // Keep the app functional with the default location.
      _hasLocationPermission = false;
      _isLocationLoaded = true; // IMPORTANT: let UI render
      _currentAddress = "Location permission not granted";
      notifyListeners();
      return;
    }

    // 2. We have permission and a position
    _hasLocationPermission = true;
    await getLiveAddressMethod(position);

    // 3. Listen to live updates only when permission is granted
    _positionStream = geolocatorPlatform
        .getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    )
        .listen(
          (Position position) => getLiveAddressMethod(position),
      onError: (e) => debugPrint('Position stream error: $e'),
    );

    notifyListeners();
  }

  Future<void> getLiveAddressMethod(Position position) async {
    _currentLatLng = LatLng(position.latitude, position.longitude);
    _isLocationLoaded = true;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentAddress =
        "${place.street}, ${place.locality}, ${place.country}";
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}