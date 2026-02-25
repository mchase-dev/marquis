import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:marquis/core/file_errors.dart';
import 'package:marquis/models/document_state.dart';
import 'package:marquis/models/tab_state.dart';
import 'package:marquis/providers/autosave_provider.dart';
import 'package:marquis/providers/file_watcher_provider.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/services/file_service.dart';

part 'tab_manager_provider.g.dart';

const _uuid = Uuid();

/// Callback for blocking error dialogs (file not found, permission denied)
typedef FileErrorCallback = void Function(String title, String message);

/// Callback for warnings that need user confirmation (large file)
/// Returns true if the user chose to continue.
typedef FileWarningCallback = Future<bool> Function(
    String title, String message);

/// Callback for non-blocking info notifications (encoding fallback)
typedef FileInfoCallback = void Function(String message);

/// Manages all open tabs and their documents [DD §6, §7]
@Riverpod(keepAlive: true)
class TabManager extends _$TabManager {
  /// Document states keyed by tab ID
  final Map<String, DocumentState> _documents = {};

  final FileService _fileService = FileService();

  /// Callbacks set by AppShell for error/warning UI [DD §24]
  FileErrorCallback? onError;
  FileWarningCallback? onWarning;
  FileInfoCallback? onInfo;

  @override
  TabManagerState build() {
    return const TabManagerState();
  }

  /// Access a document by tab ID
  DocumentState? getDocument(String tabId) => _documents[tabId];

  /// Create a new untitled tab [DD §7 — Lifecycle step 1]
  void newFile() {
    final id = _uuid.v4();

    _documents[id] = DocumentState(
      id: id,
      content: '',
      isEditMode: true, // New files open in edit mode
      lastSavedContent: null,
    );

    final tabIds = [...state.tabIds, id];
    state = state.copyWith(
      tabIds: tabIds,
      activeTabIndex: tabIds.length - 1,
    );
  }

  /// Open a file from disk [DD §7 — Lifecycle step 2, §23, §24]
  Future<void> openFile(String path) async {
    // Check if already open — switch to existing tab
    for (int i = 0; i < state.tabIds.length; i++) {
      final doc = _documents[state.tabIds[i]];
      if (doc?.filePath == path) {
        state = state.copyWith(activeTabIndex: i);
        return;
      }
    }

    ReadFileResult result;
    try {
      result = await _fileService.readFile(path);
    } on FileNotFoundException {
      onError?.call('File not found', 'File not found: $path');
      return;
    } on FilePermissionException {
      onError?.call('Permission denied', 'Permission denied: $path');
      return;
    }

    // Large file warning [DD §24]
    if (result.isLargeFile) {
      final proceed = await onWarning?.call(
        'Large file',
        'This file is very large. Editing may be slow. Continue?',
      );
      if (proceed != true) return;
    }

    final id = _uuid.v4();

    _documents[id] = DocumentState(
      id: id,
      content: result.content,
      filePath: path,
      lastSavedContent: result.content,
      lastModified: result.lastModified,
      isEditMode: false, // Opens in viewer-only mode
      encoding: result.encoding,
    );

    final tabIds = [...state.tabIds, id];
    state = state.copyWith(
      tabIds: tabIds,
      activeTabIndex: tabIds.length - 1,
    );

    // Encoding fallback notification [DD §24]
    if (result.encoding != 'utf-8') {
      onInfo?.call(
        'File opened with ${result.encoding} encoding (not valid UTF-8).',
      );
    }

    // Track in recent files [DD Appendix C]
    ref.read(preferencesProvider.notifier).addRecentFile(path);

    // Start watching for external changes [DD §15]
    ref.read(fileWatcherProvider.notifier).watchFile(id, path);
  }

  /// Open file via file picker dialog [DD §23 — Opening a File]
  Future<void> openFileDialog() async {
    final paths = await _fileService.pickFilesToOpen();
    if (paths == null || paths.isEmpty) return;

    for (final path in paths) {
      await openFile(path);
    }
  }

  /// Save the active document [DD §7 — Lifecycle step 4, §24]
  Future<void> saveActiveDocument() async {
    final activeId = state.activeTabId;
    if (activeId == null) return;

    final doc = _documents[activeId];
    if (doc == null) return;

    if (doc.filePath == null) {
      // No path yet — trigger Save As
      await saveActiveDocumentAs();
      return;
    }

    // Cancel autosave timer and suppress watcher [DD §14, §15]
    final autosave = ref.read(autosaveProvider.notifier);
    autosave.cancelTimer(activeId);

    try {
      await _fileService.writeFile(doc.filePath!, doc.content);
    } on FilePermissionException {
      onError?.call('Permission denied', 'Permission denied: ${doc.filePath}');
      return;
    } on DiskFullException {
      onError?.call(
          'Disk full', 'Not enough disk space to save: ${doc.filePath}');
      return;
    }

    autosave.state.recordWrite(doc.filePath!);
    _documents[activeId] = doc.copyWith(
      lastSavedContent: doc.content,
      lastModified: DateTime.now(),
    );

    // Track in recent files
    ref.read(preferencesProvider.notifier).addRecentFile(doc.filePath!);

    // Trigger state update for UI refresh
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Save As dialog for active document [DD §24]
  Future<void> saveActiveDocumentAs() async {
    final activeId = state.activeTabId;
    if (activeId == null) return;

    final doc = _documents[activeId];
    if (doc == null) return;

    final path = await _fileService.pickSaveAsPath(
      defaultFileName: doc.displayName,
    );
    if (path == null) return;

    try {
      await _fileService.writeFile(path, doc.content);
    } on FilePermissionException {
      onError?.call('Permission denied', 'Permission denied: $path');
      return;
    } on DiskFullException {
      onError?.call('Disk full', 'Not enough disk space to save: $path');
      return;
    }

    _documents[activeId] = doc.copyWith(
      filePath: path,
      lastSavedContent: doc.content,
      lastModified: DateTime.now(),
    );

    ref.read(preferencesProvider.notifier).addRecentFile(path);
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Save a specific document by tab ID [DD §24]
  Future<bool> saveDocument(String tabId) async {
    final doc = _documents[tabId];
    if (doc == null) return false;

    final autosave = ref.read(autosaveProvider.notifier);
    autosave.cancelTimer(tabId);

    if (doc.filePath == null) {
      final path = await _fileService.pickSaveAsPath(
        defaultFileName: doc.displayName,
      );
      if (path == null) return false;
      try {
        await _fileService.writeFile(path, doc.content);
      } on FilePermissionException {
        onError?.call('Permission denied', 'Permission denied: $path');
        return false;
      } on DiskFullException {
        onError?.call('Disk full', 'Not enough disk space to save: $path');
        return false;
      }
      autosave.state.recordWrite(path);
      _documents[tabId] = doc.copyWith(
        filePath: path,
        lastSavedContent: doc.content,
        lastModified: DateTime.now(),
      );
      // Start watching newly saved file
      ref.read(fileWatcherProvider.notifier).watchFile(tabId, path);
    } else {
      try {
        await _fileService.writeFile(doc.filePath!, doc.content);
      } on FilePermissionException {
        onError?.call(
            'Permission denied', 'Permission denied: ${doc.filePath}');
        return false;
      } on DiskFullException {
        onError?.call(
            'Disk full', 'Not enough disk space to save: ${doc.filePath}');
        return false;
      }
      autosave.state.recordWrite(doc.filePath!);
      _documents[tabId] = doc.copyWith(
        lastSavedContent: doc.content,
        lastModified: DateTime.now(),
      );
    }

    state = state.copyWith(revision: state.revision + 1);
    return true;
  }

  /// Update content of a document (called from editor) [DD §23 — Editing]
  void updateContent(String tabId, String content) {
    final doc = _documents[tabId];
    if (doc == null) return;

    _documents[tabId] = doc.copyWith(content: content);
    // Bump revision to ensure Riverpod detects the change
    state = state.copyWith(revision: state.revision + 1);

    // Trigger autosave [DD §14]
    ref.read(autosaveProvider.notifier).onContentChanged(tabId);
  }

  /// Toggle edit mode for a document
  void toggleEditMode(String tabId) {
    final doc = _documents[tabId];
    if (doc == null) return;

    _documents[tabId] = doc.copyWith(isEditMode: !doc.isEditMode);
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Switch to a tab by index [DD §6 — Switch tab]
  void setActiveTab(int index) {
    if (index < 0 || index >= state.tabIds.length) return;
    state = state.copyWith(activeTabIndex: index);
  }

  /// Close a tab by ID [DD §7 — Lifecycle step 6]
  /// Returns true if the tab was closed, false if cancelled
  void closeTab(String tabId) {
    final index = state.tabIds.indexOf(tabId);
    if (index == -1) return;

    final doc = _documents[tabId];
    // Unwatch and cancel autosave timer [DD §14, §15]
    ref.read(autosaveProvider.notifier).cancelTimer(tabId);
    if (doc?.filePath != null) {
      ref.read(fileWatcherProvider.notifier).unwatchFile(doc!.filePath!);
    }

    _documents.remove(tabId);

    final tabIds = [...state.tabIds]..removeAt(index);
    int newActiveIndex = state.activeTabIndex;

    if (tabIds.isEmpty) {
      newActiveIndex = -1;
    } else if (index <= newActiveIndex) {
      newActiveIndex = (newActiveIndex - 1).clamp(0, tabIds.length - 1);
    }

    state = state.copyWith(
      tabIds: tabIds,
      activeTabIndex: newActiveIndex,
    );
  }

  /// Close all other tabs [DD §6 — Close Others]
  void closeOtherTabs(String keepTabId) {
    final keepIndex = state.tabIds.indexOf(keepTabId);
    if (keepIndex == -1) return;

    for (final id in state.tabIds) {
      if (id != keepTabId) {
        final doc = _documents[id];
        ref.read(autosaveProvider.notifier).cancelTimer(id);
        if (doc?.filePath != null) {
          ref.read(fileWatcherProvider.notifier).unwatchFile(doc!.filePath!);
        }
        _documents.remove(id);
      }
    }

    state = state.copyWith(
      tabIds: [keepTabId],
      activeTabIndex: 0,
    );
  }

  /// Close all tabs [DD §6 — Close All]
  void closeAllTabs() {
    // Unwatch all files and cancel all timers
    for (final id in state.tabIds) {
      final doc = _documents[id];
      if (doc?.filePath != null) {
        ref.read(fileWatcherProvider.notifier).unwatchFile(doc!.filePath!);
      }
    }
    ref.read(autosaveProvider.notifier).cancelAll();
    _documents.clear();
    state = const TabManagerState();
  }

  /// Close tabs to the right [DD §6 — Close to Right]
  void closeTabsToRight(String tabId) {
    final index = state.tabIds.indexOf(tabId);
    if (index == -1) return;

    final toRemove = state.tabIds.sublist(index + 1);
    for (final id in toRemove) {
      final doc = _documents[id];
      ref.read(autosaveProvider.notifier).cancelTimer(id);
      if (doc?.filePath != null) {
        ref.read(fileWatcherProvider.notifier).unwatchFile(doc!.filePath!);
      }
      _documents.remove(id);
    }

    final tabIds = state.tabIds.sublist(0, index + 1);
    state = state.copyWith(
      tabIds: tabIds,
      activeTabIndex: state.activeTabIndex.clamp(0, tabIds.length - 1),
    );
  }

  /// Reorder tabs via drag-and-drop [DD §6 — Reorder tabs]
  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final tabIds = [...state.tabIds];
    final activeId = state.activeTabId;

    final movedId = tabIds.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex--;
    tabIds.insert(newIndex, movedId);

    // Keep the active tab tracking the same document
    final newActiveIndex =
        activeId != null ? tabIds.indexOf(activeId) : state.activeTabIndex;

    state = state.copyWith(
      tabIds: tabIds,
      activeTabIndex: newActiveIndex,
    );
  }

  /// Get list of dirty documents (for close-all prompt)
  List<DocumentState> get dirtyDocuments {
    return _documents.values.where((d) => d.isDirty).toList();
  }

  /// Check if any documents have unsaved changes
  bool get hasUnsavedChanges => _documents.values.any((d) => d.isDirty);

  /// Rename a file on disk and update the tab [DD §12 — Rename File Behavior]
  void updateFilePath(String tabId, String newPath) {
    final doc = _documents[tabId];
    if (doc == null) return;

    _documents[tabId] = doc.copyWith(filePath: newPath);
    ref.read(preferencesProvider.notifier).addRecentFile(newPath);
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Mark a document as saved (called after autosave) [DD §14]
  void markSaved(String tabId) {
    final doc = _documents[tabId];
    if (doc == null) return;

    _documents[tabId] = doc.copyWith(
      lastSavedContent: doc.content,
      lastModified: DateTime.now(),
    );
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Reload a document from disk after external change [DD §15]
  void reloadFromDisk(String tabId,
      {required String content, required DateTime lastModified}) {
    final doc = _documents[tabId];
    if (doc == null) return;

    _documents[tabId] = doc.copyWith(
      content: content,
      lastSavedContent: content,
      lastModified: lastModified,
    );
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Set externally modified flag [DD §15]
  void setExternallyModified(String tabId, bool value) {
    final doc = _documents[tabId];
    if (doc == null) return;

    _documents[tabId] = doc.copyWith(isExternallyModified: value);
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Reverse lookup: find tab ID by file path [DD §15]
  String? getTabIdForPath(String path) {
    for (final entry in _documents.entries) {
      if (entry.value.filePath == path) return entry.key;
    }
    return null;
  }

  /// Open a bundled help file as a special read-only tab [DD §12 — Help Content]
  Future<void> openHelpFile(String title, String assetPath) async {
    // Check if already open — switch to existing tab
    for (int i = 0; i < state.tabIds.length; i++) {
      final doc = _documents[state.tabIds[i]];
      if (doc?.helpTitle == title) {
        state = state.copyWith(activeTabIndex: i);
        return;
      }
    }

    final content = await rootBundle.loadString(assetPath);
    final id = _uuid.v4();

    _documents[id] = DocumentState(
      id: id,
      content: content,
      lastSavedContent: content,
      isReadOnly: true,
      helpTitle: title,
    );

    final tabIds = [...state.tabIds, id];
    state = state.copyWith(
      tabIds: tabIds,
      activeTabIndex: tabIds.length - 1,
    );
  }
}
