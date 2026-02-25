import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:marquis/providers/autosave_provider.dart';
import 'package:marquis/providers/tab_manager_provider.dart';
import 'package:marquis/services/file_service.dart';
import 'package:marquis/services/file_watcher_service.dart';

part 'file_watcher_provider.g.dart';

/// Callback type for conflict/deletion events that require UI interaction
typedef FileEventCallback = void Function(String tabId, {required bool isDeleted});

/// Callback type for silent reload notifications [DD §15 — Case 1]
typedef FileReloadCallback = void Function(String fileName);

/// Manages file watchers for open documents [DD §15]
@Riverpod(keepAlive: true)
class FileWatcherNotifier extends _$FileWatcherNotifier {
  final FileWatcherService _service = FileWatcherService();
  final FileService _fileService = FileService();

  /// Callback set by AppShell to show conflict/deleted dialogs
  FileEventCallback? onFileEvent;

  /// Callback set by AppShell to show reload notification snackbar
  FileReloadCallback? onFileReloaded;

  @override
  FileWatcherService build() {
    ref.onDispose(_service.disposeAll);
    return _service;
  }

  /// Start watching a file for external changes
  void watchFile(String tabId, String path) {
    _service.watchFile(
      path,
      onChanged: (changedPath) => _handleChanged(tabId, changedPath),
      onDeleted: (deletedPath) => _handleDeleted(tabId, deletedPath),
    );
  }

  /// Stop watching a file
  void unwatchFile(String path) {
    _service.unwatchFile(path);
  }

  void _handleChanged(String tabId, String path) {
    // Check autosave suppression — ignore events from our own saves
    final autosave = ref.read(autosaveProvider);
    if (autosave.shouldSuppressWatcher(path)) return;

    final doc = ref.read(tabManagerProvider.notifier).getDocument(tabId);
    if (doc == null) return;

    if (!doc.isDirty) {
      // No local changes — silently reload + notify [DD §15 — Case 1]
      _reloadFromDisk(tabId, path).then((_) {
        onFileReloaded?.call(doc.displayName);
      });
    } else {
      // Local changes exist — show conflict dialog via callback
      onFileEvent?.call(tabId, isDeleted: false);
    }
  }

  void _handleDeleted(String tabId, String path) {
    // Check autosave suppression
    final autosave = ref.read(autosaveProvider);
    if (autosave.shouldSuppressWatcher(path)) return;

    onFileEvent?.call(tabId, isDeleted: true);
  }

  /// Reload a document from disk (no local changes, or user chose reload)
  Future<void> reloadFromDisk(String tabId) async {
    final doc = ref.read(tabManagerProvider.notifier).getDocument(tabId);
    if (doc?.filePath == null) return;
    await _reloadFromDisk(tabId, doc!.filePath!);
  }

  Future<void> _reloadFromDisk(String tabId, String path) async {
    try {
      final result = await _fileService.readFile(path);
      ref.read(tabManagerProvider.notifier).reloadFromDisk(
        tabId,
        content: result.content,
        lastModified: result.lastModified,
      );
    } catch (_) {
      // File may have been deleted between event and read
      debugPrint('Failed to reload file: $path');
    }
  }
}
