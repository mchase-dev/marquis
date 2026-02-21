import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:marquis/app.dart';
import 'package:marquis/core/constants.dart';
import 'package:marquis/services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Load saved window state from preferences [DD §5 — Window state persistence]
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
    // Restore position if saved [DD §17 — Window settings]
    if (windowPrefs.x != null && windowPrefs.y != null) {
      await windowManager.setPosition(
        Offset(windowPrefs.x!.toDouble(), windowPrefs.y!.toDouble()),
      );
      // Validate position is on-screen [DD §5 — off-screen fallback]
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
