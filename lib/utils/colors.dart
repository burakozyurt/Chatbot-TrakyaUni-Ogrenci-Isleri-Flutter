import 'dart:ui';

import 'package:flutter/material.dart';

class ThemeColor{
  static Color primaryColor = HexColor('#CB9832');
  static Color accentColor = HexColor('#285eff'); //Blue
  static Color thirdColor = Colors.white;
  static Color triadicColor = Colors.green;
  static Color analogousColor = HexColor('#ff5e28'); // Red
  static Color passiveColor = HexColor('#dedede'); // Grey

}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}