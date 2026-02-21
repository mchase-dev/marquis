import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:marquis/core/constants.dart';
import 'package:marquis/models/preferences_state.dart';

/// Handles reading/writing preferences to a JSON file [DD §17, §24]
class PreferencesService {
  static const String _fileName = 'preferences.json';

  /// Cached file path (resolved once, reused)
  String? _cachedPath;

  /// Get the preferences file path for the current platform.
  /// Windows: %APPDATA%\Marquis\preferences.json
  /// macOS/Linux: uses path_provider default
  Future<String> get _filePath async {
    if (_cachedPath != null) return _cachedPath!;
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        _cachedPath = '$appData${Platform.pathSeparator}${AppConstants.appName}${Platform.pathSeparator}$_fileName';
        return _cachedPath!;
      }
    }
    final dir = await getApplicationSupportDirectory();
    _cachedPath = '${dir.path}${Platform.pathSeparator}$_fileName';
    return _cachedPath!;
  }

  /// Load preferences from disk. Returns defaults if file doesn't exist
  /// or is corrupt [DD §24 — Preferences file corrupt]
  Future<PreferencesState> load() async {
    try {
      final path = await _filePath;
      final file = File(path);

      if (!await file.exists()) {
        return const PreferencesState();
      }

      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return PreferencesState.fromJson(json);
    } on FormatException {
      // Corrupt JSON — backup and reset [DD §24]
      await _backupCorruptFile();
      return const PreferencesState();
    } catch (e) {
      // Any other error — return defaults
      return const PreferencesState();
    }
  }

  /// Save preferences to disk
  Future<void> save(PreferencesState state) async {
    final path = await _filePath;
    final file = File(path);

    // Ensure directory exists
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final json = const JsonEncoder.withIndent('  ').convert(state.toJson());
    await file.writeAsString(json);
  }

  /// Backup a corrupt preferences file before resetting [DD §24]
  Future<void> _backupCorruptFile() async {
    try {
      final path = await _filePath;
      final file = File(path);
      if (await file.exists()) {
        final backupPath = '$path.backup';
        await file.copy(backupPath);
      }
    } catch (_) {
      // Best effort — if backup fails, just continue
    }
  }
}
