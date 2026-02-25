import 'dart:async';
import 'dart:io';

import 'package:watcher/watcher.dart';

/// Watches files on disk for external changes [DD §15]
class FileWatcherService {
  final Map<String, StreamSubscription<WatchEvent>> _watchers = {};
  final Map<String, Timer> _debounceTimers = {};

  /// Start watching a file for changes.
  /// [onChanged] fires when the file is modified externally.
  /// [onDeleted] fires when the file is deleted.
  void watchFile(
    String path, {
    required void Function(String path) onChanged,
    required void Function(String path) onDeleted,
  }) {
    // Don't double-watch
    if (_watchers.containsKey(path)) return;

    final watcher = FileWatcher(path);
    _watchers[path] = watcher.events.listen((event) {
      // Debounce: some editors write in multiple steps
      _debounceTimers[path]?.cancel();
      _debounceTimers[path] = Timer(const Duration(milliseconds: 300), () {
        if (event.type == ChangeType.REMOVE) {
          onDeleted(path);
        } else if (event.type == ChangeType.MODIFY) {
          // Verify the file still exists (some editors delete+recreate)
          if (File(path).existsSync()) {
            onChanged(path);
          } else {
            onDeleted(path);
          }
        }
      });
    });
  }

  /// Stop watching a file
  void unwatchFile(String path) {
    _debounceTimers[path]?.cancel();
    _debounceTimers.remove(path);
    _watchers[path]?.cancel();
    _watchers.remove(path);
  }

  /// Stop all watchers
  void disposeAll() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    for (final sub in _watchers.values) {
      sub.cancel();
    }
    _watchers.clear();
  }
}
