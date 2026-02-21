import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:marquis/models/document_state.dart';
import 'package:marquis/models/tab_state.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/services/file_service.dart';

part 'tab_manager_provider.g.dart';

const _uuid = Uuid();

/// Manages all open tabs and their documents [DD §6, §7]
@Riverpod(keepAlive: true)
class TabManager extends _$TabManager {
  /// Document states keyed by tab ID
  final Map<String, DocumentState> _documents = {};

  final FileService _fileService = FileService();

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

  /// Open a file from disk [DD §7 — Lifecycle step 2, §23]
  Future<void> openFile(String path) async {
    // Check if already open — switch to existing tab
    for (int i = 0; i < state.tabIds.length; i++) {
      final doc = _documents[state.tabIds[i]];
      if (doc?.filePath == path) {
        state = state.copyWith(activeTabIndex: i);
        return;
      }
    }

    final result = await _fileService.readFile(path);
    final id = _uuid.v4();

    _documents[id] = DocumentState(
      id: id,
      content: result.content,
      filePath: path,
      lastSavedContent: result.content,
      lastModified: result.lastModified,
      isEditMode: false, // Opens in viewer-only mode
    );

    final tabIds = [...state.tabIds, id];
    state = state.copyWith(
      tabIds: tabIds,
      activeTabIndex: tabIds.length - 1,
    );

    // Track in recent files [DD Appendix C]
    ref.read(preferencesProvider.notifier).addRecentFile(path);
  }

  /// Open file via file picker dialog [DD §23 — Opening a File]
  Future<void> openFileDialog() async {
    final paths = await _fileService.pickFilesToOpen();
    if (paths == null || paths.isEmpty) return;

    for (final path in paths) {
      await openFile(path);
    }
  }

  /// Save the active document [DD §7 — Lifecycle step 4]
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

    await _fileService.writeFile(doc.filePath!, doc.content);
    _documents[activeId] = doc.copyWith(
      lastSavedContent: doc.content,
      lastModified: DateTime.now(),
    );

    // Track in recent files
    ref.read(preferencesProvider.notifier).addRecentFile(doc.filePath!);

    // Trigger state update for UI refresh
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Save As dialog for active document
  Future<void> saveActiveDocumentAs() async {
    final activeId = state.activeTabId;
    if (activeId == null) return;

    final doc = _documents[activeId];
    if (doc == null) return;

    final path = await _fileService.pickSaveAsPath(
      defaultFileName: doc.displayName,
    );
    if (path == null) return;

    await _fileService.writeFile(path, doc.content);
    _documents[activeId] = doc.copyWith(
      filePath: path,
      lastSavedContent: doc.content,
      lastModified: DateTime.now(),
    );

    ref.read(preferencesProvider.notifier).addRecentFile(path);
    state = state.copyWith(revision: state.revision + 1);
  }

  /// Save a specific document by tab ID
  Future<bool> saveDocument(String tabId) async {
    final doc = _documents[tabId];
    if (doc == null) return false;

    if (doc.filePath == null) {
      final path = await _fileService.pickSaveAsPath(
        defaultFileName: doc.displayName,
      );
      if (path == null) return false;
      await _fileService.writeFile(path, doc.content);
      _documents[tabId] = doc.copyWith(
        filePath: path,
        lastSavedContent: doc.content,
        lastModified: DateTime.now(),
      );
    } else {
      await _fileService.writeFile(doc.filePath!, doc.content);
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
      if (id != keepTabId) _documents.remove(id);
    }

    state = state.copyWith(
      tabIds: [keepTabId],
      activeTabIndex: 0,
    );
  }

  /// Close all tabs [DD §6 — Close All]
  void closeAllTabs() {
    _documents.clear();
    state = const TabManagerState();
  }

  /// Close tabs to the right [DD §6 — Close to Right]
  void closeTabsToRight(String tabId) {
    final index = state.tabIds.indexOf(tabId);
    if (index == -1) return;

    final toRemove = state.tabIds.sublist(index + 1);
    for (final id in toRemove) {
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
}
