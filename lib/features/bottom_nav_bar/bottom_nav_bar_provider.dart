import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class BottomNavBarProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// Reset the index to home tab (0)
  /// This should be called when user logs out or when navigating to sign in
  void resetIndex() {
    _currentIndex = 0;
    notifyListeners();
  }
}
