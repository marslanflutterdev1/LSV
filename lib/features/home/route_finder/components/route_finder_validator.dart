import 'package:flutter/foundation.dart';

class RouteFinderValidator extends ChangeNotifier {
  String _sourceValidate = '';
  String _destinationValidate = '';

  String get sourceValidate => _sourceValidate;
  String get destinationValidate => _destinationValidate;

  void clearAllError() {
    _sourceValidate = '';
    _destinationValidate = '';
    notifyListeners();
  }

  /// Validate Source Address
  String? setValidateSource(String value) {
    value = value.trim();

    if (value.isEmpty) {
      _sourceValidate = 'Please enter source address';
    } else if (value.length < 3) {
      _sourceValidate = 'Source address is too short';
    } else {
      _sourceValidate = '';
    }

    notifyListeners();
    return _sourceValidate.isEmpty ? null : _sourceValidate;
  }

  /// Validate Destination Address
  String? setValidateDestination(String value) {
    value = value.trim();

    if (value.isEmpty) {
      _destinationValidate = 'Please enter destination address';
    } else if (value.length < 3) {
      _destinationValidate = 'Destination address is too short';
    } else {
      _destinationValidate = '';
    }

    notifyListeners();
    return _destinationValidate.isEmpty
        ? null
        : _destinationValidate;
  }

  void clearError(String fieldName) {
    switch (fieldName) {
      case 'sourceValidate':
        _sourceValidate = "";
        break;
      case 'destinationValidate':
        _destinationValidate = '';
        break;
      default:
        debugPrint("$fieldName is not a valid field name");
        break;
    }
    notifyListeners();
  }
}
