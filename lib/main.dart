import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:marquis/app.dart';
import 'package:marquis/core/constants.dart';
import 'package:marquis/services/preferences_service.dart';

/// Command-line arguments passed at launch, used for cold-start file open
List<String> initialArgs = const [];

void main(List<String> args) async {
  initialArgs = args;
  // Suppress known debug noise from dependencies
  final defaultDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null) {
      defaultDebugPrint(message, wrapWidth: wrapWidth);
      return;
    }
    // markdown_widget: code blocks without a language class
    if (message.startsWith('get language error:')) return;
    // pdf: built-in Helvetica has no Unicode tables
    if (message.contains('has no Unicode support')) return;
    // pdf: missing glyphs (emoji, uncommon symbols)
    if (message.startsWith('Unable to find a font to draw')) return;
    defaultDebugPrint(message, wrapWidth: wrapWidth);
  };

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Load saved window state from preferences
  final prefsService = PreferencesService();
  final prefs = await prefsService.load();
  final windowPrefs = prefs.window;

  final windowOptions = WindowOptions(
    size: Size(
      windowPrefs.width.toDouble(),
      windowPrefs.height.toDouble(),
    ),
    minimumSize: const Size(
      AppConstants.minWindowWidth,
      AppConstants.minWindowHeight,
    ),
    center: windowPrefs.x == null || windowPrefs.y == null,
    title: AppConstants.appName,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Restore position if saved
    if (windowPrefs.x != null && windowPrefs.y != null) {
      await windowManager.setPosition(
        Offset(windowPrefs.x!.toDouble(), windowPrefs.y!.toDouble()),
      );
      // Validate position is on-screen
      final position = await windowManager.getPosition();
      if (position.dx < -100 || position.dy < -100) {
        await windowManager.center();
      }
    }

    if (windowPrefs.isMaximized) {
      await windowManager.maximize();
    }

    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    const ProviderScope(
      child: MarquisApp(),
    ),
  );
}
