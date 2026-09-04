import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:satellite_view/core/utils/constants.dart';
import 'package:satellite_view/features/home/nearby_places/near_by_places_model.dart';

import '../../../network/api_services.dart';
import '../../../network/custom_exception.dart';

class NearbyPlacesProvider extends ChangeNotifier {
  ApiServices apiServices = ApiServices();

  bool _isLoading = false;
  String _errorMessage = "";
  bool _errorShown = false;

  NearByPlacesModel? _nearByPlacesModel;

  bool get isLoading => _isLoading;
  String get errorMsg => _errorMessage;
  bool get isErrorShown => _errorShown;

  NearByPlacesModel? get nearByPlacesModel => _nearByPlacesModel;

  void clearError() {
    _isLoading = false;
    _errorMessage = "";
    _errorShown = true;
    notifyListeners();
  }

  Future<void> getNearByPlacesMethod({
    double? lat,
    double? lng,
    String? keyword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      _errorShown = false;
      _nearByPlacesModel = null;
      notifyListeners();

      final query = (keyword ?? '').trim();
      final encodedKeyword = Uri.encodeComponent(query);
      final placeType = _getPlaceTypeForKeyword(query);
      final radius = 5000;
      final url = StringBuffer(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=$radius',
      );

      if (placeType != null) {
        url.write('&type=$placeType');
      }
      url.write('&keyword=$encodedKeyword');
      url.write('&key=${Constants.mapKey}');

      final requestUrl = url.toString();
      log(
        '🌐 API Request URL (without key): ${requestUrl.replaceAll(RegExp(r'&key=.*'), '')}',
      );

      final jsonString = await apiServices.getRequest(requestUrl);

      if (jsonString == null || (jsonString is String && jsonString.isEmpty)) {
        log('Empty server response');
        throw ParsingException("Empty server response");
      }

      final jsonData = NearByPlacesModel.fromJson(jsonString);

      log('API Status: ${jsonData.status}');
      log('Places Found: ${jsonData.results?.length ?? 0}');

      if (jsonData.status == 'OK' &&
          jsonData.results != null &&
          jsonData.results!.isNotEmpty) {
        for (int i = 0; i < jsonData.results!.length; i++) {
          final place = jsonData.results![i];
          log('Place ${i + 1}: ${place.name}');
          log('Address: ${place.vicinity}');
          log('Open: ${place.openingHours?.openNow ?? false}');
        }

        _nearByPlacesModel = jsonData;
        _errorMessage = '';
      } else if (jsonData.status == 'ZERO_RESULTS') {
        _errorMessage = 'No places found. Try a different search term.';
        _nearByPlacesModel = null;
      } else if (jsonData.status == 'REQUEST_DENIED') {
        _errorMessage = 'The provided API key is invalid.';
        _nearByPlacesModel = null;
      } else if (jsonData.status == 'INVALID_REQUEST') {
        _errorMessage = 'Invalid request. Please check your input.';
        _nearByPlacesModel = null;
      } else {
        _errorMessage = 'Failed to fetch places. Status: ${jsonData.status}';
        _nearByPlacesModel = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (error, stackTrace) {
      _isLoading = false;
      log("Stack Trace: $stackTrace");

      if (error is NetworkException) {
        _errorMessage =
            error.errorMessage?.toString() ??
            "Please check your internet connection";
      } else if (error is TimeoutApiException) {
        _errorMessage =
            error.errorMessage?.toString() ??
            "Request timeout. Please try again";
      } else if (error is ServerException) {
        _errorMessage = "Server error. Please try again later";
      } else if (error is RedirectionException) {
        _errorMessage = "Request failed. Please try again";
      } else if (error is ClientErrorException) {
        _errorMessage =
            error.errorMessage?.toString() ??
            "Invalid credentials. Please check your details";
      } else if (error is ServerErrorException) {
        _errorMessage = "Server error. Please try again later";
      } else if (error is ParsingException) {
        _errorMessage = "Something went wrong. Please try again";
      } else {
        _errorMessage = "An unexpected error occurred. Please try again";
      }
      _errorShown = false;
      notifyListeners();
    }
  }

  String? _getPlaceTypeForKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    if (lowerKeyword.contains('petrol') ||
        lowerKeyword.contains('gas station') ||
        lowerKeyword.contains('gas') ||
        lowerKeyword.contains('fuel') ||
        lowerKeyword.contains('petrol pump')) {
      return 'gas_station';
    }
    return null;
  }
}
