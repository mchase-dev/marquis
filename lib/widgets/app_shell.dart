import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:marquis/core/constants.dart';
import 'package:marquis/models/command_item.dart';
import 'package:marquis/models/preferences_state.dart';
import 'package:marquis/providers/autosave_provider.dart';
import 'package:marquis/providers/command_palette_provider.dart';
import 'package:marquis/providers/document_provider.dart';
import 'package:marquis/providers/file_watcher_provider.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/providers/tab_manager_provider.dart';
import 'package:marquis/providers/view_mode_provider.dart';
import 'package:re_editor/re_editor.dart';
import 'package:marquis/services/formatting_service.dart';
import 'package:marquis/services/print_service.dart';
import 'package:marquis/widgets/command_palette/command_data.dart';
import 'package:marquis/widgets/command_palette/command_palette.dart';
import 'package:marquis/widgets/dialogs/conflict_dialog.dart';
import 'package:marquis/widgets/dialogs/error_dialog.dart';
import 'package:marquis/widgets/dialogs/file_deleted_dialog.dart';
import 'package:marquis/widgets/dialogs/rename_dialog.dart';
import 'package:marquis/widgets/preferences/preferences_dialog.dart';
import 'package:marquis/widgets/dialogs/save_dialog.dart';
import 'package:marquis/widgets/editor/editor_pane.dart';
import 'package:marquis/widgets/editor/editor_toolbar.dart';
import 'package:marquis/widgets/menu_bar/app_menu_bar.dart';
import 'package:marquis/widgets/split_view/split_view.dart';
import 'package:marquis/widgets/status_bar/status_bar.dart';
import 'package:marquis/widgets/tab_bar/app_tab_bar.dart';
import 'package:marquis/widgets/viewer/viewer_pane.dart';
import 'package:marquis/widgets/welcome/welcome_screen.dart';

/// Top-level layout scaffold [DD §5 — Window Layout]
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WindowListener {
  Timer? _saveWindowStateTimer;
  bool _isClosing = false;

  // Cached window state — updated on resize/move, written to disk on close
  Size _lastSize = const Size(1200, 800);
  Offset _lastPosition = Offset.zero;
  bool _lastMaximized = false;

  // Editor/viewer keys for accessing state
  final _editorKey = GlobalKey<EditorPaneState>();
  final _viewerKey = GlobalKey<ViewerPaneState>();

  // Tracks which pane last received a pointer-down (for context-sensitive find)
  bool _viewerHasFocus = false;

  // Scroll controllers for sync [DD §10 — Scroll Synchronization]
  final _viewerScrollController = ScrollController();
  final _editorVerticalScroller = ScrollController();
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    _captureWindowState();
    _editorVerticalScroller.addListener(_onEditorScroll);
    _viewerScrollController.addListener(_onViewerScroll);
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);

    // Register file watcher callback for conflict/deletion dialogs [DD §15]
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileWatcherProvider.notifier).onFileEvent = _onFileEvent;
      ref.read(fileWatcherProvider.notifier).onFileReloaded = _onFileReloaded;

      // Register error callbacks for file operations [DD §24]
      final tabManager = ref.read(tabManagerProvider.notifier);
      tabManager.onError = _onFileError;
      tabManager.onWarning = _onFileWarning;
      tabManager.onInfo = _showInfoSnackBar;
      ref.read(autosaveProvider.notifier).onSaveError = _onSaveError;

      // Listen for tab switches to trigger autosave [DD §14]
      ref.listenManual(tabManagerProvider.select((s) => s.activeTabIndex), (_, _) {
        ref.read(autosaveProvider.notifier).saveAllDirty();
      });
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _saveWindowStateTimer?.cancel();
    _editorVerticalScroller.removeListener(_onEditorScroll);
    _viewerScrollController.removeListener(_onViewerScroll);
    _editorVerticalScroller.dispose();
    _viewerScrollController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Scroll sync [DD §10]
  // ---------------------------------------------------------------------------

  void _onEditorScroll() {
    if (_isSyncingScroll) return;
    if (!_editorVerticalScroller.hasClients || !_viewerScrollController.hasClients) return;
    final editorMax = _editorVerticalScroller.position.maxScrollExtent;
    if (editorMax <= 0) return;
    final fraction = _editorVerticalScroller.offset / editorMax;
    final viewerMax = _viewerScrollController.position.maxScrollExtent;
    _isSyncingScroll = true;
    _viewerScrollController.jumpTo((fraction * viewerMax).clamp(0, viewerMax));
    _isSyncingScroll = false;
  }

  void _onViewerScroll() {
    if (_isSyncingScroll) return;
    if (!_viewerScrollController.hasClients || !_editorVerticalScroller.hasClients) return;
    final viewerMax = _viewerScrollController.position.maxScrollExtent;
    if (viewerMax <= 0) return;
    final fraction = _viewerScrollController.offset / viewerMax;
    final editorMax = _editorVerticalScroller.position.maxScrollExtent;
    _isSyncingScroll = true;
    _editorVerticalScroller.jumpTo((fraction * editorMax).clamp(0, editorMax));
    _isSyncingScroll = false;
  }

  // ---------------------------------------------------------------------------
  // Window state persistence [DD §5]
  // ---------------------------------------------------------------------------

  Future<void> _captureWindowState() async {
    final results = await Future.wait([
      windowManager.isMaximized(),
      windowManager.getSize(),
      windowManager.getPosition(),
    ]);
    _lastMaximized = results[0] as bool;
    _lastSize = results[1] as Size;
    _lastPosition = results[2] as Offset;
  }

  Future<void> _persistWindowState() async {
    await ref.read(preferencesProvider.notifier).updatePreferences((current) {
      return current.copyWith(
        window: WindowPrefs(
          width: _lastSize.width.round(),
          height: _lastSize.height.round(),
          x: _lastPosition.dx.round(),
          y: _lastPosition.dy.round(),
          isMaximized: _lastMaximized,
        ),
      );
    });
  }

  void _debouncedSaveWindowState() {
    if (_isClosing) return;
    _saveWindowStateTimer?.cancel();
    _saveWindowStateTimer = Timer(const Duration(milliseconds: 500), () async {
      await _captureWindowState();
      await _persistWindowState();
    });
  }

  void _updateWindowTitle() {
    final activeDoc = ref.read(activeDocumentProvider);
    if (activeDoc != null) {
      final dirty = activeDoc.isDirty ? '● ' : '';
      windowManager.setTitle('$dirty${activeDoc.displayName} — ${AppConstants.appName}');
    } else {
      windowManager.setTitle(AppConstants.appName);
    }
  }

  // ---------------------------------------------------------------------------
  // Window listener callbacks
  // ---------------------------------------------------------------------------

  @override
  void onWindowClose() async {
    _isClosing = true;
    _saveWindowStateTimer?.cancel();
    ref.read(autosaveProvider.notifier).cancelAll();

    final tabManager = ref.read(tabManagerProvider.notifier);
    if (tabManager.hasUnsavedChanges) {
      final dirtyDocs = tabManager.dirtyDocuments;
      if (!mounted) {
        _isClosing = false;
        return;
      }
      final result = await SaveDialog.showMultiple(
        context,
        fileCount: dirtyDocs.length,
      );

      if (result == null || result == SaveDialogResult.cancel) {
        _isClosing = false;
        return;
      }

      if (result == SaveDialogResult.save) {
        for (final doc in dirtyDocs) {
          final saved = await tabManager.saveDocument(doc.id);
          if (!saved) {
            _isClosing = false;
            return;
          }
        }
      }
    }

    await _persistWindowState();
    exit(0);
  }

  @override
  void onWindowResized() => _debouncedSaveWindowState();

  @override
  void onWindowMoved() => _debouncedSaveWindowState();

  @override
  void onWindowBlur() {
    // Auto-save all dirty documents when window loses focus [DD §14]
    ref.read(autosaveProvider.notifier).saveAllDirty();
  }

  // ---------------------------------------------------------------------------
  // Action handlers (shared between menu, command palette, and shortcuts)
  // ---------------------------------------------------------------------------

  void _closeActiveTab() {
    final tabState = ref.read(tabManagerProvider);
    final activeId = tabState.activeTabId;
    if (activeId == null) return;

    final tabManager = ref.read(tabManagerProvider.notifier);
    final doc = tabManager.getDocument(activeId);

    if (doc != null && doc.isDirty) {
      _showSavePromptForTab(activeId, doc.displayName);
    } else {
      tabManager.closeTab(activeId);
    }
  }

  Future<void> _closeAllTabs() async {
    final tabManager = ref.read(tabManagerProvider.notifier);
    if (tabManager.hasUnsavedChanges) {
      final dirtyDocs = tabManager.dirtyDocuments;
      final result = await SaveDialog.showMultiple(
        context,
        fileCount: dirtyDocs.length,
      );
      if (result == null || result == SaveDialogResult.cancel) return;
      if (result == SaveDialogResult.save) {
        for (final doc in dirtyDocs) {
          final saved = await tabManager.saveDocument(doc.id);
          if (!saved) return;
        }
      }
    }
    tabManager.closeAllTabs();
  }

  Future<void> _showSavePromptForTab(String tabId, String displayName) async {
    final result = await SaveDialog.showSingle(
      context,
      fileName: displayName,
    );
    if (result == null || result == SaveDialogResult.cancel) return;

    final tabManager = ref.read(tabManagerProvider.notifier);
    if (result == SaveDialogResult.save) {
      final saved = await tabManager.saveDocument(tabId);
      if (!saved) return;
    }
    tabManager.closeTab(tabId);
  }

  void _nextTab() {
    final tabState = ref.read(tabManagerProvider);
    if (tabState.tabCount <= 1) return;
    final next = (tabState.activeTabIndex + 1) % tabState.tabCount;
    ref.read(tabManagerProvider.notifier).setActiveTab(next);
  }

  void _previousTab() {
    final tabState = ref.read(tabManagerProvider);
    if (tabState.tabCount <= 1) return;
    final prev = (tabState.activeTabIndex - 1 + tabState.tabCount) %
        tabState.tabCount;
    ref.read(tabManagerProvider.notifier).setActiveTab(prev);
  }

  void _goToTab(int index) {
    final tabState = ref.read(tabManagerProvider);
    if (index < tabState.tabCount) {
      ref.read(tabManagerProvider.notifier).setActiveTab(index);
    }
  }

  void _toggleCommandPalette() {
    ref.read(commandPaletteProvider.notifier).toggle();
  }

  void _onFind() {
    // Context-sensitive find [DD §16]
    final viewMode = ref.read(viewModeProvider);
    final activeDoc = ref.read(activeDocumentProvider);
    // Compute effective view mode (same logic as build)
    final effectiveViewMode = (activeDoc != null &&
            !activeDoc.isReadOnly &&
            activeDoc.isEditMode &&
            viewMode == ViewMode.viewerOnly)
        ? ViewMode.split
        : (activeDoc != null && activeDoc.isReadOnly)
            ? ViewMode.viewerOnly
            : viewMode;

    if (effectiveViewMode == ViewMode.viewerOnly ||
        (effectiveViewMode == ViewMode.split && _viewerHasFocus)) {
      // Viewer context → viewer find bar
      _viewerKey.currentState?.showFind();
    } else {
      // Editor context → ensure editor visible, open editor find
      if (viewMode == ViewMode.viewerOnly) {
        ref.read(viewModeProvider.notifier).toggleEdit();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editorKey.currentState?.showFind();
      });
    }
  }

  void _onFindReplace() {
    // Context-sensitive find/replace [DD §16]
    final viewMode = ref.read(viewModeProvider);
    final activeDoc = ref.read(activeDocumentProvider);
    final effectiveViewMode = (activeDoc != null &&
            !activeDoc.isReadOnly &&
            activeDoc.isEditMode &&
            viewMode == ViewMode.viewerOnly)
        ? ViewMode.split
        : (activeDoc != null && activeDoc.isReadOnly)
            ? ViewMode.viewerOnly
            : viewMode;

    if (effectiveViewMode == ViewMode.viewerOnly ||
        (effectiveViewMode == ViewMode.split && _viewerHasFocus)) {
      // Viewer has no replace — just open find
      _viewerKey.currentState?.showFind();
    } else {
      // Editor context → find+replace
      if (viewMode == ViewMode.viewerOnly) {
        ref.read(viewModeProvider.notifier).toggleEdit();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editorKey.currentState?.showFindReplace();
      });
    }
  }

  void _onPreferences() {
    PreferencesDialog.show(context);
  }

  Future<void> _onPrint() async {
    final activeDoc = ref.read(activeDocumentProvider);
    if (activeDoc == null) return;

    final prefs = ref.read(preferencesProvider).value;
    final fontSize = prefs?.appearance.viewerFontSize.toDouble() ?? 16;

    try {
      await PrintService.printDocument(
        content: activeDoc.content,
        documentName: activeDoc.displayName,
        filePath: activeDoc.filePath,
        fontSize: fontSize,
      );
    } catch (e) {
      if (!mounted) return;
      _showInfoSnackBar('Print failed: $e');
    }
  }

  Future<void> _onRename() async {
    final activeDoc = ref.read(activeDocumentProvider);
    if (activeDoc == null || activeDoc.isUntitled || activeDoc.isReadOnly) return;

    final newPath = await RenameDialog.show(
      context,
      currentFileName: activeDoc.displayName,
      currentFilePath: activeDoc.filePath!,
    );

    if (newPath != null) {
      ref.read(tabManagerProvider.notifier).updateFilePath(activeDoc.id, newPath);
    }
  }

  void _onAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Marquis',
      applicationVersion: AppConstants.version,
      applicationLegalese: 'Marquis de Editeur',
      applicationIcon: Image.asset(
        'assets/icons/app_icon_master.png',
        width: 64,
        height: 64,
      ),
    );
  }

  void _onUserGuide() {
    ref.read(tabManagerProvider.notifier).openHelpFile(
      'User Guide',
      'assets/help/user_guide.md',
    );
  }

  void _onMarkdownReference() {
    ref.read(tabManagerProvider.notifier).openHelpFile(
      'Markdown Reference',
      'assets/help/markdown_reference.md',
    );
  }

  Future<void> _toggleFullScreen() async {
    final isFullScreen = await windowManager.isFullScreen();
    windowManager.setFullScreen(!isFullScreen);
  }

  void _zoomIn() {
    ref.read(preferencesProvider.notifier).updatePreferences((current) {
      final newZoom = (current.appearance.zoomLevel + 10).clamp(50, 200);
      return current.copyWith(
        appearance: current.appearance.copyWith(zoomLevel: newZoom),
      );
    });
  }

  void _zoomOut() {
    ref.read(preferencesProvider.notifier).updatePreferences((current) {
      final newZoom = (current.appearance.zoomLevel - 10).clamp(50, 200);
      return current.copyWith(
        appearance: current.appearance.copyWith(zoomLevel: newZoom),
      );
    });
  }

  void _zoomReset() {
    ref.read(preferencesProvider.notifier).updatePreferences((current) {
      return current.copyWith(
        appearance: current.appearance.copyWith(zoomLevel: 100),
      );
    });
  }

  void _toggleTheme() {
    ref.read(preferencesProvider.notifier).updatePreferences((current) {
      final nextTheme = current.appearance.theme == ThemeModePref.dark
          ? ThemeModePref.light
          : ThemeModePref.dark;
      return current.copyWith(
        appearance: current.appearance.copyWith(theme: nextTheme),
      );
    });
  }

  void _quit() {
    onWindowClose();
  }

  // ---------------------------------------------------------------------------
  // File watcher conflict/deletion handling [DD §15]
  // ---------------------------------------------------------------------------

  void _onFileReloaded(String fileName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$fileName" was updated from disk.'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        width: 360,
      ),
    );
  }

  void _onFileEvent(String tabId, {required bool isDeleted}) {
    if (!mounted) return;
    final tabManager = ref.read(tabManagerProvider.notifier);
    final doc = tabManager.getDocument(tabId);
    if (doc == null) return;

    if (isDeleted) {
      _showFileDeletedDialog(tabId, doc.displayName);
    } else {
      _showConflictDialog(tabId, doc.displayName);
    }
  }

  Future<void> _showConflictDialog(String tabId, String fileName) async {
    final result = await ConflictDialog.show(context, fileName: fileName);
    if (result == null) return;

    if (result == ConflictDialogResult.reload) {
      await ref.read(fileWatcherProvider.notifier).reloadFromDisk(tabId);
    }
    // keepLocal — do nothing, keep the local version
  }

  Future<void> _showFileDeletedDialog(String tabId, String fileName) async {
    final result = await FileDeletedDialog.show(context, fileName: fileName);
    if (result == null) return;

    final tabManager = ref.read(tabManagerProvider.notifier);
    switch (result) {
      case FileDeletedResult.closeTab:
        tabManager.closeTab(tabId);
      case FileDeletedResult.saveAs:
        await tabManager.saveDocument(tabId);
      case FileDeletedResult.saveToOriginal:
        final doc = tabManager.getDocument(tabId);
        if (doc?.filePath != null) {
          await File(doc!.filePath!).writeAsString(doc.content);
          tabManager.markSaved(tabId);
        }
    }
  }

  // ---------------------------------------------------------------------------
  // File operation error handling [DD §24]
  // ---------------------------------------------------------------------------

  void _onFileError(String title, String message) {
    if (!mounted) return;
    ErrorDialog.show(context, title: title, message: message);
  }

  Future<bool> _onFileWarning(String title, String message) async {
    if (!mounted) return false;
    return ErrorDialog.showWarning(context, title: title, message: message);
  }

  void _onSaveError(String fileName, String message) {
    if (!mounted) return;
    _showInfoSnackBar(message);
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        width: 400,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Command palette handling [DD §11]
  // ---------------------------------------------------------------------------

  void _onCommandSelected(CommandItem item) {
    ref.read(commandPaletteProvider.notifier).close();

    if (item.isSnippet) {
      // Ensure editor is open [DD §11 — "If the editor is not open..."]
      final viewMode = ref.read(viewModeProvider);
      if (viewMode == ViewMode.viewerOnly) {
        ref.read(viewModeProvider.notifier).toggleEdit();
      }
      // Insert snippet at cursor
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = _editorKey.currentState?.controller;
        if (controller != null && item.snippet != null) {
          controller.replaceSelection(item.snippet!);
        }
      });
    } else if (item.action != null) {
      item.action!();
    }
  }

  List<CommandItem> _buildCommandList() {
    return [
      ...CommandData.snippets(),
      ...CommandData.appCommands(
        onNewFile: () => ref.read(tabManagerProvider.notifier).newFile(),
        onOpenFile: () => ref.read(tabManagerProvider.notifier).openFileDialog(),
        onSave: () => ref.read(tabManagerProvider.notifier).saveActiveDocument(),
        onSaveAs: () => ref.read(tabManagerProvider.notifier).saveActiveDocumentAs(),
        onCloseTab: _closeActiveTab,
        onToggleEditMode: () => ref.read(viewModeProvider.notifier).toggleEdit(),
        onFind: _onFind,
        onFindReplace: _onFindReplace,
        onPreferences: _onPreferences,
        onToggleTheme: _toggleTheme,
        onPrint: _onPrint,
        onAbout: _onAbout,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Global keyboard shortcuts via HardwareKeyboard [DD §13]
  //
  // We use HardwareKeyboard.instance.addHandler() instead of
  // CallbackShortcuts because CallbackShortcuts relies on focus-tree
  // bubbling — events consumed by re_editor or lost after command palette
  // closure never reach it.  HardwareKeyboard fires BEFORE the focus tree.
  // ---------------------------------------------------------------------------

  bool _handleGlobalKeyEvent(KeyEvent event) {
    // When command palette is open, only handle Ctrl+/ to toggle it closed
    final paletteState = ref.read(commandPaletteProvider);
    if (paletteState.isOpen) {
      const togglePalette = SingleActivator(LogicalKeyboardKey.slash, control: true);
      if (togglePalette.accepts(event, HardwareKeyboard.instance)) {
        _toggleCommandPalette();
        return true;
      }
      return false; // Let all other events reach the palette's TextField
    }

    // Check global shortcuts
    for (final entry in _globalShortcuts.entries) {
      if (entry.key.accepts(event, HardwareKeyboard.instance)) {
        entry.value();
        return true;
      }
    }

    // Formatting shortcuts — only when editor is visible
    final controller = _editorKey.currentState?.controller;
    if (controller != null) {
      for (final entry in _formattingShortcuts(controller).entries) {
        if (entry.key.accepts(event, HardwareKeyboard.instance)) {
          entry.value();
          return true;
        }
      }
    }

    return false; // Not handled — pass to focus tree (re_editor, etc.)
  }

  Map<ShortcutActivator, VoidCallback> get _globalShortcuts => {
    // File operations
    const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
        ref.read(tabManagerProvider.notifier).newFile(),
    const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
        ref.read(tabManagerProvider.notifier).openFileDialog(),
    const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
        ref.read(tabManagerProvider.notifier).saveActiveDocument(),
    const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): () =>
        ref.read(tabManagerProvider.notifier).saveActiveDocumentAs(),
    const SingleActivator(LogicalKeyboardKey.keyW, control: true): _closeActiveTab,
    const SingleActivator(LogicalKeyboardKey.keyW, control: true, shift: true): _closeAllTabs,
    const SingleActivator(LogicalKeyboardKey.f2): _onRename,
    const SingleActivator(LogicalKeyboardKey.keyP, control: true): _onPrint,
    const SingleActivator(LogicalKeyboardKey.keyQ, control: true): _quit,
    const SingleActivator(LogicalKeyboardKey.comma, control: true): _onPreferences,

    // Command palette [DD §11]
    const SingleActivator(LogicalKeyboardKey.slash, control: true): _toggleCommandPalette,

    // View mode toggles [DD §10]
    const SingleActivator(LogicalKeyboardKey.keyE, control: true): () =>
        ref.read(viewModeProvider.notifier).toggleEdit(),
    const SingleActivator(LogicalKeyboardKey.keyE, control: true, shift: true): () =>
        ref.read(viewModeProvider.notifier).toggleEditorOnly(),

    // Find [DD §16]
    const SingleActivator(LogicalKeyboardKey.keyF, control: true): _onFind,
    const SingleActivator(LogicalKeyboardKey.keyH, control: true): _onFindReplace,

    // Zoom [DD §13]
    const SingleActivator(LogicalKeyboardKey.equal, control: true): _zoomIn,
    const SingleActivator(LogicalKeyboardKey.minus, control: true): _zoomOut,
    const SingleActivator(LogicalKeyboardKey.digit0, control: true): _zoomReset,

    // Full screen [DD §13]
    const SingleActivator(LogicalKeyboardKey.f11): _toggleFullScreen,

    // Tab navigation [DD §13]
    const SingleActivator(LogicalKeyboardKey.tab, control: true): _nextTab,
    const SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true): _previousTab,

    // Go to tab 1–9 (Alt+1 through Alt+9) [DD §13]
    const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () => _goToTab(0),
    const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () => _goToTab(1),
    const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () => _goToTab(2),
    const SingleActivator(LogicalKeyboardKey.digit4, alt: true): () => _goToTab(3),
    const SingleActivator(LogicalKeyboardKey.digit5, alt: true): () => _goToTab(4),
    const SingleActivator(LogicalKeyboardKey.digit6, alt: true): () => _goToTab(5),
    const SingleActivator(LogicalKeyboardKey.digit7, alt: true): () => _goToTab(6),
    const SingleActivator(LogicalKeyboardKey.digit8, alt: true): () => _goToTab(7),
    const SingleActivator(LogicalKeyboardKey.digit9, alt: true): () => _goToTab(8),
  };

  Map<ShortcutActivator, VoidCallback> _formattingShortcuts(
    CodeLineEditingController controller,
  ) => {
    const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
        FormattingService.bold(controller),
    const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
        FormattingService.italic(controller),
    const SingleActivator(LogicalKeyboardKey.keyS, alt: true): () =>
        FormattingService.strikethrough(controller),
    const SingleActivator(LogicalKeyboardKey.backquote, control: true): () =>
        FormattingService.inlineCode(controller),
    const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
        FormattingService.link(controller),
    const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
        FormattingService.heading(controller, 1),
    const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
        FormattingService.heading(controller, 2),
    const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
        FormattingService.heading(controller, 3),
    const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
        FormattingService.heading(controller, 4),
    const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
        FormattingService.heading(controller, 5),
    const SingleActivator(LogicalKeyboardKey.digit6, control: true): () =>
        FormattingService.heading(controller, 6),
    const SingleActivator(LogicalKeyboardKey.digit8, control: true, shift: true): () =>
        FormattingService.unorderedList(controller),
    const SingleActivator(LogicalKeyboardKey.digit9, control: true, shift: true): () =>
        FormattingService.orderedList(controller),
    const SingleActivator(LogicalKeyboardKey.keyX, control: true, shift: true): () =>
        FormattingService.taskList(controller),
    const SingleActivator(LogicalKeyboardKey.period, control: true, shift: true): () =>
        FormattingService.blockQuote(controller),
    const SingleActivator(LogicalKeyboardKey.keyK, control: true, shift: true): () =>
        FormattingService.codeBlock(controller),
    const SingleActivator(LogicalKeyboardKey.minus, control: true, shift: true): () =>
        FormattingService.horizontalRule(controller),
  };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabManagerProvider);
    final activeDoc = ref.watch(activeDocumentProvider);
    final viewMode = ref.watch(viewModeProvider);
    final paletteState = ref.watch(commandPaletteProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateWindowTitle());

    // Determine effective view mode: new/untitled files open in edit mode
    // Help/read-only docs stay in viewer-only mode
    final effectiveViewMode = (activeDoc != null &&
            !activeDoc.isReadOnly &&
            activeDoc.isEditMode &&
            viewMode == ViewMode.viewerOnly)
        ? ViewMode.split
        : (activeDoc != null && activeDoc.isReadOnly)
            ? ViewMode.viewerOnly
            : viewMode;

    final showEditor = effectiveViewMode == ViewMode.split ||
        effectiveViewMode == ViewMode.editorOnly;

    final scaffold = Scaffold(
      body: Column(
        children: [
          const AppTabBar(),
          // Editor toolbar — shown when editor is visible and not read-only
          if (tabState.hasTabs &&
              activeDoc != null &&
              showEditor &&
              !activeDoc.isReadOnly)
            EditorToolbar(
              controller: _editorKey.currentState?.controller ??
                  _placeholderController,
              onCommandPalette: _toggleCommandPalette,
            ),
          Expanded(
            child: tabState.hasTabs && activeDoc != null
                ? SplitView(
                    viewMode: effectiveViewMode,
                    editor: Listener(
                      onPointerDown: (_) => _viewerHasFocus = false,
                      child: EditorPane(
                        key: _editorKey,
                        content: activeDoc.content,
                        tabId: activeDoc.id,
                        onChanged: (content) {
                          ref.read(tabManagerProvider.notifier)
                              .updateContent(activeDoc.id, content);
                        },
                        scrollController: CodeScrollController(
                          verticalScroller: _editorVerticalScroller,
                          horizontalScroller: ScrollController(),
                        ),
                      ),
                    ),
                    viewer: Listener(
                      onPointerDown: (_) => _viewerHasFocus = true,
                      child: ViewerPane(
                        key: _viewerKey,
                        content: activeDoc.content,
                        filePath: activeDoc.filePath,
                        scrollController: _viewerScrollController,
                      ),
                    ),
                  )
                : const WelcomeScreen(),
          ),
          const StatusBar(),
        ],
      ),
    );

    // Wrap with menu bar
    final withMenuBar = AppMenuBar(
      onCommandPalette: _toggleCommandPalette,
      onFind: _onFind,
      onFindReplace: _onFindReplace,
      onPreferences: _onPreferences,
      onPrint: _onPrint,
      onRename: _onRename,
      onAbout: _onAbout,
      onUserGuide: _onUserGuide,
      onMarkdownReference: _onMarkdownReference,
      onToggleFullScreen: _toggleFullScreen,
      onZoomIn: _zoomIn,
      onZoomOut: _zoomOut,
      onZoomReset: _zoomReset,
      onCloseTab: _closeActiveTab,
      onCloseAllTabs: _closeAllTabs,
      onQuit: _quit,
      child: scaffold,
    );

    return DropTarget(
      onDragDone: (details) {
        for (final file in details.files) {
          final path = file.path;
          if (path.endsWith('.md') || path.endsWith('.markdown')) {
            ref.read(tabManagerProvider.notifier).openFile(path);
          }
        }
      },
      child: Stack(
        children: [
          withMenuBar,
          // Command palette overlay [DD §11]
          if (paletteState.isOpen)
            CommandPalette(
              commands: _buildCommandList(),
              onSelect: _onCommandSelected,
              onClose: () => ref.read(commandPaletteProvider.notifier).close(),
            ),
        ],
      ),
    );
  }

  static final _placeholderController = CodeLineEditingController();
}
