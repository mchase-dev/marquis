import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:marquis/core/constants.dart';
import 'package:marquis/models/preferences_state.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/theme/app_theme.dart';

part 'theme_provider.g.dart';

/// Derives the ThemeMode from user preferences [DD §20 — Theme Implementation]
@riverpod
ThemeMode themeMode(Ref ref) {
  final prefsAsync = ref.watch(preferencesProvider);
  final prefs = prefsAsync.value;
  if (prefs == null) return ThemeMode.system;

  return switch (prefs.appearance.theme) {
    ThemeModePref.light => ThemeMode.light,
    ThemeModePref.dark => ThemeMode.dark,
    ThemeModePref.system => ThemeMode.system,
  };
}

/// Derives the accent Color from user preferences [DD §20 — Accent Color]
@riverpod
Color accentColor(Ref ref) {
  final prefsAsync = ref.watch(preferencesProvider);
  final prefs = prefsAsync.value;
  if (prefs == null) return AppConstants.defaultAccentColor;

  return AppTheme.parseHexColor(prefs.appearance.accentColor);
}

/// Builds the light ThemeData from the accent color
@riverpod
ThemeData lightTheme(Ref ref) {
  return AppTheme.light(ref.watch(accentColorProvider));
}

/// Builds the dark ThemeData from the accent color
@riverpod
ThemeData darkTheme(Ref ref) {
  return AppTheme.dark(ref.watch(accentColorProvider));
}
