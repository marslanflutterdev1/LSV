import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class StreetViewProvider extends ChangeNotifier {
  final List<Country> _countries = [];
  final List<Country> _searchResults = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _showSuggestions = false;
  String _searchQuery = '';
  Country? _selectedCountry;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get hasQuery => _searchQuery.trim().isNotEmpty;
  bool get shouldShowSuggestions => _showSuggestions && hasQuery;
  bool get hasResults => _searchResults.isNotEmpty;
  String get searchQuery => _searchQuery;
  Country? get selectedCountry => _selectedCountry;
  List<Country> get searchResults => List.unmodifiable(_searchResults);

  Future<void> loadCountries() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final jsonString =
      await rootBundle.loadString('assets/json/countries.json');
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      _countries.clear();
      _countries.addAll(decoded.map(
            (dynamic item) => Country.fromJson(item as Map<String, dynamic>),
      ));
      _hasError = false;
    } catch (_) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _selectedCountry = null;
    _showSuggestions = query.trim().isNotEmpty;
    _searchResults.clear();

    final searchText = query.trim().toLowerCase();
    if (searchText.isEmpty) {
      notifyListeners();
      return;
    }

    _searchResults.addAll(_countries.where((country) {
      return country.countryName.toLowerCase().contains(searchText) ||
          country.countryCode.toLowerCase().contains(searchText);
    }));

    notifyListeners();
  }

  void selectCountry(Country country) {
    _selectedCountry = country;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    _showSuggestions = false;
    notifyListeners();
  }
}

class Country {
  Country({
    required this.countryCode,
    required this.countryName,
    this.flagImage,
    required this.places,
  });

  final String countryCode;
  final String countryName;
  final String? flagImage;
  final List<Place> places;

  factory Country.fromJson(Map<String, dynamic> json) {
    final rawPlaces = json['places'] as List<dynamic>? ?? <dynamic>[];
    return Country(
      countryCode: json['countryCode'] as String? ?? '',
      countryName: json['countryName'] as String? ?? '',
      flagImage: json['flagImage'] as String?,
      places: rawPlaces
          .map((dynamic placeJson) =>
          Place.fromJson(placeJson as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Place {
  Place({
    this.placeName,
    this.placeImage,
    this.address,
  });

  final String? placeName;
  final String? placeImage;
  final String? address;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      placeName: json['placeName'] as String?,
      placeImage: json['placeImage'] as String?,
      address: json['address'] as String?,
    );
  }
}