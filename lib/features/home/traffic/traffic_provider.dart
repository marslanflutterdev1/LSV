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
  LatLng currentLatLng = const LatLng(31.5204, 74.3587);
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

  // ✅ Accept customMarker from screen
  Future<void> getCurrentLocation({BitmapDescriptor? customMarker}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    currentPosition = await Geolocator.getCurrentPosition();
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
        // ✅ Use custom marker if ready, else default
        icon: customMarker ?? BitmapDescriptor.defaultMarker,
      ),
    );

    await mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLatLng, zoom: 16),
      ),
    );

    notifyListeners();
  }

  // ✅ Accept customMarker from screen
  Future<void> searchLocation({BitmapDescriptor? customMarker}) async {
    if (searchController.text.trim().isEmpty) return;

    isLoading = true;
    notifyListeners();

    try {
      List<Location> locations = await locationFromAddress(
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
            // ✅ Use custom marker if ready, else default
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
}