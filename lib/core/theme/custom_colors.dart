import 'package:flutter/material.dart';

class CustomColors {
  CustomColors._();

  static Color custom(String c) {
    final int color = int.parse('0xFF$c');
    return Color(color);
  }

  static Color trans = Colors.transparent;
  static Color white = Colors.white;
  static Color black = Colors.black;
  static Color grey = Colors.grey;
  static Color grey200 = Colors.grey.shade200;
  static Color error = const Color(0xffC80815);
  static Color whiteWithOpacity = const Color(0x80FFFFFF);
  static Color blackWithOpacity = const Color(0xff5B5B60);
  static Color primaryColor = const Color(0xff004226);
  static Color iconBackgroundColor = const Color(0xffE5ECE9);

}
