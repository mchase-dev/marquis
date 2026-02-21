import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:marquis/core/constants.dart';
import 'package:marquis/models/preferences_state.dart';
import 'package:marquis/providers/document_provider.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/providers/tab_manager_provider.dart';
import 'package:marquis/providers/view_mode_provider.dart';
import 'package:re_editor/re_editor.dart';
import 'package:marquis/services/formatting_service.dart';
import 'package:marquis/widgets/dialogs/save_dialog.dart';
import 'package:marquis/widgets/editor/editor_pane.dart';
import 'package:marquis/widgets/editor/editor_toolbar.dart';
import 'package:marquis/widgets/split_view/split_view.dart';
import 'package:marquis/widgets/status_bar/status_bar.dart';
import 'package:marquis/widgets/tab_bar/app_tab_bar.dart';
import 'package:marquis/widgets/toolbar/app_toolbar.dart';
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

  // Editor key for accessing the editor controller
  final _editorKey = GlobalKey<EditorPaneState>();

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
  }

  @override
  void dispose() {
    _saveWindowStateTimer?.cancel();
    _editorVerticalScroller.removeListener(_onEditorScroll);
    _viewerScrollController.removeListener(_onViewerScroll);
    _editorVerticalScroller.dispose();
    _viewerScrollController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  /// Proportional scroll sync: editor -> viewer [DD §10]
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

  /// Proportional scroll sync: viewer -> editor [DD §10]
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

  /// Capture current window state into memory (no file I/O)
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

  /// Persist cached window state to preferences file [DD §5]
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

  /// Debounced: capture window state then persist
  void _debouncedSaveWindowState() {
    if (_isClosing) return;
    _saveWindowStateTimer?.cancel();
    _saveWindowStateTimer = Timer(const Duration(milliseconds: 500), () async {
      await _captureWindowState();
      await _persistWindowState();
    });
  }

  /// Update window title based on active document [DD §5 — Title]
  void _updateWindowTitle() {
    final activeDoc = ref.read(activeDocumentProvider);
    if (activeDoc != null) {
      final dirty = activeDoc.isDirty ? '● ' : '';
      windowManager.setTitle('$dirty${activeDoc.displayName} — ${AppConstants.appName}');
    } else {
      windowManager.setTitle(AppConstants.appName);
    }
  }

  @override
  void onWindowClose() async {
    _isClosing = true;
    _saveWindowStateTimer?.cancel();

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
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabManagerProvider);
    final activeDoc = ref.watch(activeDocumentProvider);
    final viewMode = ref.watch(viewModeProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateWindowTitle());

    // Determine effective view mode: new/untitled files open in edit mode
    final effectiveViewMode = (activeDoc != null && activeDoc.isEditMode && viewMode == ViewMode.viewerOnly)
        ? ViewMode.split
        : viewMode;

    final showEditor = effectiveViewMode == ViewMode.split ||
        effectiveViewMode == ViewMode.editorOnly;

    return CallbackShortcuts(
      bindings: _buildShortcuts(),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              const AppToolbar(),
              const AppTabBar(),
              // Editor toolbar — shown when editor is visible
              if (tabState.hasTabs && activeDoc != null && showEditor)
                EditorToolbar(
                  controller: _editorKey.currentState?.controller ??
                      _placeholderController,
                ),
              Expanded(
                child: tabState.hasTabs && activeDoc != null
                    ? SplitView(
                        viewMode: effectiveViewMode,
                        editor: EditorPane(
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
                        viewer: ViewerPane(
                          content: activeDoc.content,
                          filePath: activeDoc.filePath,
                          scrollController: _viewerScrollController,
                        ),
                      )
                    : const WelcomeScreen(),
              ),
              const StatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  // Placeholder controller used before editor mounts
  static final _placeholderController = CodeLineEditingController();

  /// Keyboard shortcuts [DD §13 — partial, expanded in Phase 5]
  Map<ShortcutActivator, VoidCallback> _buildShortcuts() {
    final tabManager = ref.read(tabManagerProvider.notifier);
    final viewModeNotifier = ref.read(viewModeProvider.notifier);

    return {
      // File operations
      const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
        tabManager.newFile();
      },
      const SingleActivator(LogicalKeyboardKey.keyO, control: true): () {
        tabManager.openFileDialog();
      },
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
        tabManager.saveActiveDocument();
      },
      const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): () {
        tabManager.saveActiveDocumentAs();
      },
      const SingleActivator(LogicalKeyboardKey.keyW, control: true): () {
        _closeActiveTab();
      },
      // Tab navigation [DD §6 — Switch tab]
      const SingleActivator(LogicalKeyboardKey.tab, control: true): () {
        _nextTab();
      },
      const SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true): () {
        _previousTab();
      },
      // View mode toggles [DD §10 — Toggling Edit Mode]
      const SingleActivator(LogicalKeyboardKey.keyE, control: true): () {
        viewModeNotifier.toggleEdit();
      },
      const SingleActivator(LogicalKeyboardKey.keyE, control: true, shift: true): () {
        viewModeNotifier.toggleEditorOnly();
      },
      // Formatting shortcuts [DD §8 — Markdown Formatting Shortcuts]
      ..._buildFormattingShortcuts(),
    };
  }

  Map<ShortcutActivator, VoidCallback> _buildFormattingShortcuts() {
    final controller = _editorKey.currentState?.controller;
    if (controller == null) return {};

    return {
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
  }

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
}
