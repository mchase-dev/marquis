import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:marquis/core/file_errors.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/providers/tab_manager_provider.dart';
import 'package:marquis/services/autosave_service.dart';
import 'package:marquis/services/file_service.dart';

part 'autosave_provider.g.dart';

/// Callback for autosave failures that should be surfaced to the user
typedef SaveErrorCallback = void Function(String fileName, String message);

/// Manages autosave lifecycle — debounced saves on content change
@Riverpod(keepAlive: true)
class Autosave extends _$Autosave {
  final AutosaveService _service = AutosaveService();
  final FileService _fileService = FileService();

  /// Callback set by AppShell to show save-failure snackbar
  SaveErrorCallback? onSaveError;

  @override
  AutosaveService build() {
    ref.onDispose(_service.dispose);
    return _service;
  }

  /// Called when document content changes — schedules an autosave if enabled
  void onContentChanged(String tabId) {
    final prefs = ref.read(preferencesProvider).value;
    if (prefs == null) return;
    if (!prefs.autosave.enabled) return;

    final doc = ref.read(tabManagerProvider.notifier).getDocument(tabId);
    if (doc == null) return;

    // Skip untitled documents (no path to save to) and read-only docs
    if (doc.isUntitled || doc.isReadOnly) return;

    // Skip if not dirty
    if (!doc.isDirty) return;

    _service.scheduleSave(
      tabId,
      delay: Duration(seconds: prefs.autosave.delaySec),
      saveAction: () => _performSave(tabId),
    );
  }

  /// Actually perform the save
  Future<void> _performSave(String tabId) async {
    final doc = ref.read(tabManagerProvider.notifier).getDocument(tabId);
    if (doc == null || doc.filePath == null || !doc.isDirty) return;

    try {
      await _fileService.writeFile(doc.filePath!, doc.content);
      _service.recordWrite(doc.filePath!);
      ref.read(tabManagerProvider.notifier).markSaved(tabId);
    } on FilePermissionException {
      onSaveError?.call(
        doc.displayName,
        'Autosave failed — permission denied: ${doc.filePath}',
      );
    } on DiskFullException {
      onSaveError?.call(
        doc.displayName,
        'Autosave failed — disk full. Content is still in memory.',
      );
    } catch (_) {
      // Other failures — document remains dirty, user can manually save
      onSaveError?.call(
        doc.displayName,
        'Autosave failed for "${doc.displayName}". You can save manually.',
      );
    }
  }

  /// Save all dirty documents that have file paths (blur, tab switch, close)
  Future<void> saveAllDirty() async {
    final tabManager = ref.read(tabManagerProvider.notifier);
    final tabState = ref.read(tabManagerProvider);
    final prefs = ref.read(preferencesProvider).value;
    if (prefs == null || !prefs.autosave.enabled) return;

    for (final tabId in tabState.tabIds) {
      final doc = tabManager.getDocument(tabId);
      if (doc == null || doc.isUntitled || doc.isReadOnly || !doc.isDirty) {
        continue;
      }
      _service.cancelTimer(tabId);
      await _performSave(tabId);
    }
  }

  /// Cancel timer for a specific tab
  void cancelTimer(String tabId) {
    _service.cancelTimer(tabId);
  }

  /// Cancel all timers
  void cancelAll() {
    _service.cancelAll();
  }
}
