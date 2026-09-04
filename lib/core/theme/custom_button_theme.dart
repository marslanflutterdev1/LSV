import 'package:flutter/material.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';

class CustomButtonTheme {
  CustomButtonTheme._();

  /// Light Theme.
  static final customLightButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 10.0,
      iconColor: CustomColors.black,
      foregroundColor: CustomColors.white,
      backgroundColor: CustomColors.primaryColor,
      padding: EdgeInsets.symmetric(vertical: 10),
      disabledBackgroundColor: CustomColors.primaryColor.withAlpha((0.6 * 255).round()),
      textStyle: TextStyle(
        fontSize: 16,
        color: CustomColors.black,
        fontWeight: FontWeight.bold,
        fontFamily: "",
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
    ),
  );

  /// Dark Theme.
  static final customDarkButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 10.0,
      iconColor: CustomColors.white,
      foregroundColor: CustomColors.white,
      backgroundColor: CustomColors.primaryColor,
      padding: EdgeInsets.symmetric(vertical: 10),
      disabledBackgroundColor: CustomColors.primaryColor.withAlpha((0.6 * 255).round()),
      textStyle: TextStyle(
        color: CustomColors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: "",
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
    ),
  );
}
