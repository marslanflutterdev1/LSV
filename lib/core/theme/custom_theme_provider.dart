import 'dart:developer';
import 'package:flutter/material.dart';
import '../../local/local_sp.dart';

class CustomThemeProvider extends ChangeNotifier {
  bool _isDarkTheme = false;
  bool get isDarkTheme => _isDarkTheme;

  CustomThemeProvider() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    _isDarkTheme = LocalSP.getBoolData('isDartTheme');
    log('Value $_isDarkTheme');
    notifyListeners();
  }

  Future<void> setIsDarkTheme(bool value) async {
    _isDarkTheme = value;
    await LocalSP.setBoolData('isDartTheme', value);
    notifyListeners();
  }
}
