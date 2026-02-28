import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:marquis/core/constants.dart';

void main() {
  group('AppConstants', () {
    test('app name is Marquis', () {
      expect(AppConstants.appName, 'Marquis');
    });

    test('bundle ID is com.marquis.editor', () {
      expect(AppConstants.bundleId, 'com.marquis.editor');
    });

    test('default accent color is #6C63FF', () {
      expect(AppConstants.defaultAccentColor, const Color(0xFF6C63FF));
    });

    test('default window dimensions', () {
      expect(AppConstants.defaultWindowWidth, 1200);
      expect(AppConstants.defaultWindowHeight, 800);
    });

    test('minimum window dimensions', () {
      expect(AppConstants.minWindowWidth, 800);
      expect(AppConstants.minWindowHeight, 600);
    });

    test('default font sizes', () {
      expect(AppConstants.defaultEditorFontSize, 14);
      expect(AppConstants.defaultViewerFontSize, 16);
    });

    test('default editor font family is JetBrains Mono', () {
      expect(AppConstants.defaultEditorFontFamily, 'JetBrains Mono');
    });

    test('markdown extensions include md and markdown', () {
      expect(AppConstants.markdownExtensions, contains('md'));
      expect(AppConstants.markdownExtensions, contains('markdown'));
      expect(AppConstants.markdownExtensions.length, 2);
    });

    test('autosave delay default is 3 seconds', () {
      expect(AppConstants.defaultAutosaveDelaySec, 3);
    });

    test('default max recent files is 10', () {
      expect(AppConstants.defaultMaxRecentFiles, 10);
    });

    test('default tab size is 4', () {
      expect(AppConstants.defaultTabSize, 4);
    });
  });
}
