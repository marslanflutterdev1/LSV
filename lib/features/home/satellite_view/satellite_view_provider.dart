import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:satellite_view/widgets/custom_location_permission_handler.dart';

class SatelliteViewProvider extends ChangeNotifier {

  final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;

  LatLng _currentLatLng = const LatLng(0, 0);
  String _currentAddress = "Current address...";
  StreamSubscription<Position>? _positionStream;
  bool _isLocationLoaded = false;

  LatLng get currentLatLng => _currentLatLng;
  String get currentAddress => _currentAddress;
  StreamSubscription<Position>? get positionStream => _positionStream;
  bool get isLocationLoaded => _isLocationLoaded;


  Future<void> getLiveLocationMethod() async {

    final position = await CustomLocationPermissionHandler.determinePosition();

    getLiveAddressMethod(position);

    /// Listen live location updates
    _positionStream = geolocatorPlatform.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, /// update every 5 meters
      ),
    ).listen((Position position) {
      getLiveAddressMethod(position);
    });

    notifyListeners();
  }

  Future<void> getLiveAddressMethod(Position position) async {

    _currentLatLng = LatLng(position.latitude, position.longitude);
    _isLocationLoaded = true;

    /// Convert coordinates to address
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks.first;

    _currentAddress = "${place.street}, ${place.locality}, ${place.country}";

    notifyListeners();
  }


  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

}

