import 'package:flutter/material.dart';

/// Editor-specific color definitions for light and dark modes [DD §20 — Editor Theming]
class EditorTheme {
  EditorTheme._();

  // --- Light mode ---
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightGutterBackground = Color(0xFFF5F5F5);
  static const Color lightGutterText = Color(0xFF999999);
  static const Color lightActiveLineBackground = Color(0xFFFCFCE0);
  static const Color lightText = Color(0xFF24292E);
  static const Color lightSelection = Color(0xFFB3D7FF);

  // --- Dark mode ---
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkGutterBackground = Color(0xFF252526);
  static const Color darkGutterText = Color(0xFF858585);
  static const Color darkActiveLineBackground = Color(0xFF2A2D2E);
  static const Color darkText = Color(0xFFD4D4D4);
  static const Color darkSelection = Color(0xFF264F78);
}
