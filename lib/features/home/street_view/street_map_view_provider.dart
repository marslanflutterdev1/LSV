import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class StreetMapViewProvider extends ChangeNotifier {
  double? latitude;
  double? longitude;

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";

  Future<void> initializeWebView(String address) async {
    try {
      isLoading = true;
      hasError = false;
      errorMessage = "";
      notifyListeners();

      if (address.trim().isEmpty) {
        throw Exception("Empty address");
      }

      final List<Location> locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        throw Exception("Location not found");
      }

      latitude = locations.first.latitude;
      longitude = locations.first.longitude;

      isLoading = false;
      hasError = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      hasError = true;
      errorMessage = "Street View not available for this address";
      notifyListeners();
    }
  }
}