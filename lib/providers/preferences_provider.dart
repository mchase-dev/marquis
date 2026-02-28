import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:marquis/models/preferences_state.dart';
import 'package:marquis/services/preferences_service.dart';

part 'preferences_provider.g.dart';

/// Provides reactive access to user preferences
@Riverpod(keepAlive: true)
class Preferences extends _$Preferences {
  late final PreferencesService _service;

  @override
  Future<PreferencesState> build() async {
    _service = PreferencesService();
    return _service.load();
  }

  /// Update preferences and persist to disk
  Future<void> updatePreferences(
    PreferencesState Function(PreferencesState current) updater,
  ) async {
    final current = state.value ?? const PreferencesState();
    final updated = updater(current);
    state = AsyncData(updated);
    await _service.save(updated);
  }

  /// Add a file path to the recent files list [DD Appendix C]
  Future<void> addRecentFile(String filePath) async {
    await updatePreferences((current) {
      final recentFiles = List<String>.from(current.general.recentFiles);
      recentFiles.remove(filePath);
      recentFiles.insert(0, filePath);
      while (recentFiles.length > current.general.maxRecentFiles) {
        recentFiles.removeLast();
      }
      return current.copyWith(
        general: current.general.copyWith(recentFiles: recentFiles),
      );
    });
  }

  /// Clear the recent files list
  Future<void> clearRecentFiles() async {
    await updatePreferences((current) {
      return current.copyWith(
        general: current.general.copyWith(recentFiles: []),
      );
    });
  }
}
