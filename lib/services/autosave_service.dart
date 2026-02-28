import 'dart:async';

/// Manages debounced per-document autosave timers and write-suppression
/// for file watcher integration
class AutosaveService {
  /// Per-tab debounce timers
  final Map<String, Timer> _timers = {};

  /// Tracks when we last wrote to a path, for watcher suppression
  final Map<String, DateTime> _lastWriteTimes = {};

  /// Schedule a debounced save for a tab.
  /// Cancels any existing timer and starts a new one.
  void scheduleSave(
    String tabId, {
    required Duration delay,
    required void Function() saveAction,
  }) {
    _timers[tabId]?.cancel();
    _timers[tabId] = Timer(delay, saveAction);
  }

  /// Cancel the timer for a specific tab
  void cancelTimer(String tabId) {
    _timers[tabId]?.cancel();
    _timers.remove(tabId);
  }

  /// Cancel all timers (app close)
  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Record that we just wrote to a path (for watcher suppression)
  void recordWrite(String path) {
    _lastWriteTimes[path] = DateTime.now();
  }

  /// Returns true if we wrote to this path within the last 2 seconds.
  /// Used to suppress file watcher events triggered by our own saves.
  bool shouldSuppressWatcher(String path) {
    final lastWrite = _lastWriteTimes[path];
    if (lastWrite == null) return false;
    return DateTime.now().difference(lastWrite).inMilliseconds < 2000;
  }

  void dispose() {
    cancelAll();
    _lastWriteTimes.clear();
  }
}
