import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:marquis/providers/tab_manager_provider.dart';

/// Handles single-instance file opening via app_links [DD §19]
///
/// Supports both cold start (command-line args) and warm start
/// (another instance sends a file path via WM_COPYDATA / D-Bus / macOS open).
class AppLinksService {
  AppLinksService(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _sub;

  /// Initialize with command-line args and start listening for warm-start links.
  void init(List<String> initialArgs) {
    // Cold start: open files from command-line args
    _openFilesFromArgs(initialArgs);

    // Warm start: listen for new files from other instances
    _sub = AppLinks().stringLinkStream.listen(_onLink);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _onLink(String link) {
    final path = _extractFilePath(link);
    if (path != null) _openFile(path);
  }

  void _openFilesFromArgs(List<String> args) {
    for (final arg in args) {
      final path = _extractFilePath(arg);
      if (path != null) {
        _openFile(path);
      }
    }
  }

  /// Extract a usable file path from a string that may be:
  /// - A file:// URI (Windows warm start, macOS)
  /// - A raw file path (Linux, cold start)
  String? _extractFilePath(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    String path;
    if (trimmed.startsWith('file://')) {
      // Decode file:// URI to a local path
      final uri = Uri.tryParse(trimmed);
      if (uri == null) return null;
      path = uri.toFilePath();
    } else {
      path = trimmed;
    }

    // Only accept Markdown files
    final lower = path.toLowerCase();
    if (!lower.endsWith('.md') && !lower.endsWith('.markdown')) {
      return null;
    }

    // Verify the file exists
    if (!File(path).existsSync()) return null;

    return path;
  }

  void _openFile(String path) {
    _ref.read(tabManagerProvider.notifier).openFile(path);
    windowManager.show();
    windowManager.focus();
  }
}
