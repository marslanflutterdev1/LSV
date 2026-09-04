import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/theme/custom_colors.dart';

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
      notifyListeners();

      List<Location> locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        throw Exception("Location not found");
      }

      latitude = locations.first.latitude;
      longitude = locations.first.longitude;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      hasError = true;
      errorMessage = "Street View not available for this address";
      notifyListeners();
    }
  }
}