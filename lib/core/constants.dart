import 'dart:ui';

/// App-wide constants [DD §25]
class AppConstants {
  AppConstants._();

  // App metadata
  static const String appName = 'Marquis';
  static const String appFullName = 'Marquis de Editeur';
  static const String appTagline =
      'Marquis de Editeur, the Noble Markdown Editor';
  static const String bundleId = 'com.marquis.editor';
  static const String version = '1.0.0';

  // Default accent color [DD §20]
  static const Color defaultAccentColor = Color(0xFF6C63FF);

  // Window defaults [DD §5]
  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;

  // Editor defaults [DD §17]
  static const double defaultEditorFontSize = 14;
  static const double defaultViewerFontSize = 16;
  static const String defaultEditorFontFamily = 'JetBrains Mono';
  static const int defaultTabSize = 4;
  static const int defaultZoomLevel = 100;

  // Autosave defaults [DD §14, §17]
  static const int defaultAutosaveDelaySec = 3;

  // Recent files [DD §17]
  static const int defaultMaxRecentFiles = 10;

  // File extensions [DD §7]
  static const List<String> markdownExtensions = ['md', 'markdown'];

  // Split view [DD §10]
  static const double minPaneWidth = 200;
  static const Duration slideAnimationDuration = Duration(milliseconds: 300);
}
