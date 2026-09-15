import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrafficProvider extends ChangeNotifier {
  GoogleMapController? mapController;
  TextEditingController searchController = TextEditingController();
  bool trafficEnabled = true;
  bool satelliteMode = false;
  bool isLoading = false;

  Position? currentPosition;

  /// Default fallback location shown when permission is denied.
  /// Change this to a meaningful default for your app.
  LatLng currentLatLng = const LatLng(31.5204, 74.3587);

  /// Whether the user has granted location permission.
  /// Drives UI decisions (blue dot, my-location button, marker).
  bool hasLocationPermission = false;

  Set<Marker> markers = {};

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  void toggleTraffic() {
    trafficEnabled = !trafficEnabled;
    notifyListeners();
  }

  void toggleSatellite() {
    satelliteMode = !satelliteMode;
    notifyListeners();
  }

  /// Returns true only if the user has granted permission.
  /// Never throws — always safe to call.
  Future<bool> _ensureLocationPermission() async {
    try {
      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        hasLocationPermission = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        hasLocationPermission = false;
        notifyListeners();
        return false;
      }

      hasLocationPermission = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Location permission error: $e');
      hasLocationPermission = false;
      notifyListeners();
      return false;
    }
  }

  /// Gets the user's current location.
  /// If permission is denied, the app keeps working with the default
  /// LatLng and no location marker is added.
  Future<void> getCurrentLocation({BitmapDescriptor? customMarker}) async {
    final bool granted = await _ensureLocationPermission();

    if (!granted) {
      // No permission — do NOT add marker, do NOT move camera.
      // App remains functional using the default currentLatLng.
      return;
    }

    try {
      currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      currentLatLng = LatLng(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );

      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLatLng,
          infoWindow: const InfoWindow(title: 'My Current Location'),
          icon: customMarker ?? BitmapDescriptor.defaultMarker,
        ),
      );

      await mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLatLng, zoom: 16),
        ),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('getCurrentLocation error: $e');
    }
  }

  /// Searches for an address. Does NOT require location permission.
  Future<void> searchLocation({BitmapDescriptor? customMarker}) async {
    if (searchController.text.trim().isEmpty) return;

    isLoading = true;
    notifyListeners();

    try {
      final List<Location> locations = await locationFromAddress(
        searchController.text.trim(),
      );

      if (locations.isNotEmpty) {
        final location = locations.first;
        final searchedLocation = LatLng(
          location.latitude,
          location.longitude,
        );

        markers.clear();
        markers.add(
          Marker(
            markerId: const MarkerId('searchedLocation'),
            position: searchedLocation,
            infoWindow: InfoWindow(title: searchController.text.trim()),
            icon: customMarker ?? BitmapDescriptor.defaultMarker,
          ),
        );

        await mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: searchedLocation, zoom: 15),
          ),
        );

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Search Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> zoomIn() async {
    await mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> zoomOut() async {
    await mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}