import 'package:flutter/material.dart';

/// App-wide light and dark ThemeData definitions
class AppTheme {
  AppTheme._();

  /// Build a light ThemeData using the given accent color
  static ThemeData light(Color accentColor) {
    return ThemeData(
      brightness: Brightness.light,
      colorSchemeSeed: accentColor,
      useMaterial3: true,
      fontFamily: null, // Use default system font for UI
    );
  }

  /// Build a dark ThemeData using the given accent color
  static ThemeData dark(Color accentColor) {
    return ThemeData(
      brightness: Brightness.dark,
      colorSchemeSeed: accentColor,
      useMaterial3: true,
      fontFamily: null,
    );
  }

  /// Parse a hex color string (e.g., "#6C63FF") to a Color
  static Color parseHexColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
