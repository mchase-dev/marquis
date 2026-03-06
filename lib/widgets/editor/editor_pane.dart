import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

import 'package:marquis/providers/cursor_position_provider.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/services/formatting_service.dart';
import 'package:marquis/theme/editor_theme.dart';
import 'package:marquis/widgets/editor/find_replace_bar.dart';

/// Markdown source editor using re_editor
class EditorPane extends ConsumerStatefulWidget {
  final String content;
  final String tabId;
  final ValueChanged<String> onChanged;
  final CodeScrollController? scrollController;

  const EditorPane({
    super.key,
    required this.content,
    required this.tabId,
    required this.onChanged,
    this.scrollController,
  });

  @override
  ConsumerState<EditorPane> createState() => EditorPaneState();
}

class EditorPaneState extends ConsumerState<EditorPane> {
  final Map<String, CodeLineEditingController> _controllers = {};
  late CodeLineEditingController _controller;
  late CodeScrollController _scrollController;
  late CodeFindController _findController;
  final FocusNode _editorFocusNode = FocusNode(canRequestFocus: false);
  bool _isExternalUpdate = false;
  bool _showFindBar = false;
  bool _showReplace = false;

  /// Pending list continuation recorded by the key handler, applied after
  /// re_editor finishes inserting its newline.
  ({String prefix, bool exit, int lineIndex})? _pendingListContinuation;

  /// Expose controller for formatting shortcuts
  CodeLineEditingController get controller => _controller;

  /// Expose find controller
  CodeFindController get findController => _findController;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.content);
    _controllers[widget.tabId] = _controller;
    _scrollController = widget.scrollController ??
        CodeScrollController(
          verticalScroller: ScrollController(),
          horizontalScroller: ScrollController(),
        );
    _findController = CodeFindController(_controller);
    _controller.addListener(_onControllerChanged);
    HardwareKeyboard.instance.addHandler(_handleEditorKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleEditorKeyEvent);
    _editorFocusNode.dispose();
    _controller.removeListener(_onControllerChanged);
    _findController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    // Dispose _controller if its tab was already closed (removed from map)
    if (!_controllers.containsValue(_controller)) {
      _controller.dispose();
    }
    _controllers.clear();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(EditorPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabId != oldWidget.tabId) {
      // Tab switch — suppress onChanged until after the frame completes.
      // CodeEditor.didUpdateWidget fires during build when it receives the
      // new controller, triggering notifyListeners → onChanged.
      _isExternalUpdate = true;

      // Swap to the stored (or new) controller
      final oldController = _controller;
      oldController.removeListener(_onControllerChanged);
      _findController.dispose();

      _controller = _controllers.putIfAbsent(
        widget.tabId,
        () => CodeLineEditingController.fromText(widget.content),
      );
      _findController = CodeFindController(_controller);
      _controller.addListener(_onControllerChanged);

      // Close find/replace bar — search context doesn't carry across tabs
      _showFindBar = false;
      _showReplace = false;

      // Update scroll controller if provided per-tab
      if (widget.scrollController != null) {
        _scrollController = widget.scrollController!;
      }

      // Dispose old controller if its tab was closed (removed from map)
      if (!_controllers.containsValue(oldController)) {
        oldController.dispose();
      }

      // Sync content if it diverged while tab was inactive (e.g. file reload)
      if (_controller.text != widget.content) {
        _controller.text = widget.content;
      }

      // Keep _isExternalUpdate true until after the frame — CodeEditor's
      // didUpdateWidget fires during build when it receives the new controller,
      // which triggers notifyListeners → onChanged.  Suppressing until the
      // frame completes avoids modifying Riverpod state during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isExternalUpdate = false;
      });
    } else if (widget.content != oldWidget.content &&
        widget.content != _controller.text) {
      // Same tab, content changed externally (e.g. file reload)
      _isExternalUpdate = true;
      _controller.text = widget.content;
      _isExternalUpdate = false;
    }
  }

  /// Dispose the controller for a closed tab to free its undo/redo history.
  void disposeTab(String tabId) {
    final controller = _controllers.remove(tabId);
    if (controller != null && !identical(controller, _controller)) {
      controller.dispose();
    }
  }

  /// Record list continuation intent on plain Enter so we can post-process
  /// after re_editor inserts its newline.  Returns `false` so re_editor still
  /// handles the Enter normally.
  bool _handleEditorKeyEvent(KeyEvent event) {
    if (event is KeyUpEvent) return false;
    if (!_editorFocusNode.hasFocus) return false;

    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return false;
    }

    // Only plain Enter — ignore Shift+Enter, Ctrl+Enter, etc.
    final kb = HardwareKeyboard.instance;
    if (kb.isShiftPressed ||
        kb.isControlPressed ||
        kb.isAltPressed ||
        kb.isMetaPressed) {
      return false;
    }

    // Respect the autoIndent preference
    final prefs = ref.read(preferencesProvider).value;
    if (prefs?.editor.autoIndent != true) return false;

    final sel = _controller.selection;
    if (sel.baseIndex != sel.extentIndex ||
        sel.baseOffset != sel.extentOffset) {
      return false;
    }

    final lineIndex = sel.baseIndex;
    final lineText = _controller.codeLines[lineIndex].text;
    final result = FormattingService.analyzeListLine(lineText);
    if (result == null) return false;

    _pendingListContinuation = (
      prefix: result.prefix,
      exit: result.exit,
      lineIndex: lineIndex,
    );

    // Let re_editor handle Enter — we post-process in _onControllerChanged.
    return false;
  }

  void _onControllerChanged() {
    // Apply pending list continuation after re_editor processes Enter.
    final pending = _pendingListContinuation;
    if (pending != null) {
      final sel = _controller.selection;
      // Verify the cursor moved to the expected new line.
      if (sel.baseIndex == pending.lineIndex + 1 &&
          sel.baseIndex == sel.extentIndex &&
          sel.baseOffset == sel.extentOffset) {
        _pendingListContinuation = null;
        FormattingService.applyListContinuationAfterNewline(
          _controller,
          originalLineIndex: pending.lineIndex,
          prefix: pending.prefix,
          exit: pending.exit,
        );
        // Notify parent of the updated text.
        widget.onChanged(_controller.text);
        return;
      }
      // Cursor didn't move as expected — clear stale pending action.
      _pendingListContinuation = null;
    }

    // Defer cursor-position provider update — this listener can fire during
    // the widget tree build (e.g. CodeEditor.initState sets its delegate),
    // which would violate Riverpod's "no modifications during build" rule.
    Future(() {
      if (!mounted) return;
      final selection = _controller.selection;
      // Line is 0-based in re_editor, display as 1-based
      ref.read(cursorPositionProvider.notifier).update(
        selection.extentIndex + 1,
        selection.extentOffset + 1,
      );
    });
  }

  /// Open find bar (Ctrl+F)
  void showFind() {
    setState(() {
      _showFindBar = true;
      _showReplace = false;
    });
    _findController.findMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findController.focusOnFindInput();
    });
  }

  /// Open find & replace bar (Ctrl+H)
  void showFindReplace() {
    setState(() {
      _showFindBar = true;
      _showReplace = true;
    });
    _findController.replaceMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findController.focusOnFindInput();
    });
  }

  /// Close find bar
  void closeFindBar() {
    setState(() {
      _showFindBar = false;
      _showReplace = false;
    });
    _findController.close();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(preferencesProvider).value;
    final fontSize = prefs?.appearance.editorFontSize.toDouble() ?? 14;
    final fontFamily = prefs?.appearance.editorFontFamily ?? 'JetBrains Mono';
    final showLineNumbers = prefs?.editor.showLineNumbers ?? true;
    final wordWrap = prefs?.editor.wordWrap ?? true;
    final highlightActiveLine = prefs?.editor.highlightActiveLine ?? true;

    final style = _buildStyle(
      isDark: isDark,
      fontSize: fontSize,
      fontFamily: fontFamily,
      highlightActiveLine: highlightActiveLine,
    );

    return Column(
      children: [
        if (_showFindBar)
          FindReplaceBar(
            findController: _findController,
            showReplace: _showReplace,
            onClose: closeFindBar,
          ),
        Expanded(
          child: Focus(
            focusNode: _editorFocusNode,
            child: CodeEditor(
              controller: _controller,
              scrollController: _scrollController,
              findController: _findController,
              style: style,
              wordWrap: wordWrap,
              autofocus: false,
              onChanged: (_) {
                if (!_isExternalUpdate) {
                  widget.onChanged(_controller.text);
                }
              },
              indicatorBuilder: showLineNumbers
                  ? (context, editingController, chunkController, notifier) {
                      return DefaultCodeLineNumber(
                        controller: editingController,
                        notifier: notifier,
                      );
                    }
                  : null,
              chunkAnalyzer: const NonCodeChunkAnalyzer(),
              sperator: showLineNumbers
                  ? Container(width: 1, color: isDark ? EditorTheme.darkGutterText.withValues(alpha: 0.3) : EditorTheme.lightGutterText.withValues(alpha: 0.3))
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  CodeEditorStyle _buildStyle({
    required bool isDark,
    required double fontSize,
    required String fontFamily,
    required bool highlightActiveLine,
  }) {
    return CodeEditorStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontHeight: 1.5,
      textColor: isDark ? EditorTheme.darkText : EditorTheme.lightText,
      backgroundColor:
          isDark ? EditorTheme.darkBackground : EditorTheme.lightBackground,
      selectionColor:
          isDark ? EditorTheme.darkSelection : EditorTheme.lightSelection,
      cursorColor: Theme.of(context).colorScheme.primary,
      cursorWidth: 2.0,
      cursorLineColor: highlightActiveLine
          ? (isDark
              ? EditorTheme.darkActiveLineBackground
              : EditorTheme.lightActiveLineBackground)
          : Colors.transparent,
      codeTheme: CodeHighlightTheme(
        languages: {
          'markdown': CodeHighlightThemeMode(mode: langMarkdown),
        },
        theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
      ),
    );
  }
}
