import '../widgets/custom_cherry_toast.dart';
import 'package:flutter/material.dart';

class GloblePopScopeProvider extends ChangeNotifier {
  DateTime _timeBackPressed = DateTime.now();

  bool handleBackPress(BuildContext context) {
    final differenceTime = DateTime.now().difference(_timeBackPressed);

    final isExitWarning = differenceTime >= const Duration(seconds: 2);

    _timeBackPressed = DateTime.now();

    if (isExitWarning) {
      CustomCherryToast.warning(context, title: 'Press back again to exit');
      return false;

      /// features not exit
    } else {
      return true;

      /// features exit
    }
  }
}
