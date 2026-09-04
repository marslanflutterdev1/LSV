import 'package:flutter/material.dart';
import 'package:satellite_view/core/theme/custom_button_theme.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';
import 'package:satellite_view/core/theme/custom_text_theme.dart';

class CustomTheme {
  CustomTheme._();

  /// Light Theme
  static ThemeData customLightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    // fontFamily: "UberMove",
    scaffoldBackgroundColor: CustomColors.white,
    textTheme: CustomTextTheme.customLightTextTheme,
    primaryColor: CustomColors.primaryColor,
    colorScheme: ColorScheme.light(primary: CustomColors.primaryColor, onPrimary: CustomColors.black),
    elevatedButtonTheme: CustomButtonTheme.customLightButtonTheme,
    iconTheme: IconThemeData(color: CustomColors.grey200),
  );

/// If Dark Theme Then UnCommit
static ThemeData customDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  // fontFamily: "UberMove",
  scaffoldBackgroundColor: CustomColors.black,
  textTheme: CustomTextTheme.customDarkTextTheme,
  primaryColor: CustomColors.primaryColor,
  colorScheme: ColorScheme.dark(primary: CustomColors.primaryColor, onPrimary: CustomColors.white),
  elevatedButtonTheme: CustomButtonTheme.customDarkButtonTheme,
  iconTheme: IconThemeData(color: CustomColors.grey200),
);

}
