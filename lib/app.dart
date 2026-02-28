import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/core/constants.dart';
import 'package:marquis/providers/theme_provider.dart';
import 'package:marquis/widgets/app_shell.dart';

/// Root widget for the Marquis app
class MarquisApp extends ConsumerWidget {
  const MarquisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
