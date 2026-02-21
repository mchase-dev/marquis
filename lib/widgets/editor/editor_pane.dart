import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/theme/editor_theme.dart';

/// Markdown source editor using re_editor [DD §8]
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
  late CodeLineEditingController _controller;
  late CodeScrollController _scrollController;
  bool _isExternalUpdate = false;

  /// Expose controller for formatting shortcuts
  CodeLineEditingController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.content);
    _scrollController = widget.scrollController ??
        CodeScrollController(
          verticalScroller: ScrollController(),
          horizontalScroller: ScrollController(),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(EditorPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update content if it changed externally (e.g. file reload)
    if (widget.content != oldWidget.content &&
        widget.content != _controller.text) {
      _isExternalUpdate = true;
      _controller.text = widget.content;
      _isExternalUpdate = false;
    }
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

    return CodeEditor(
      controller: _controller,
      scrollController: _scrollController,
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
          'xml': CodeHighlightThemeMode(mode: langXml),
        },
        theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
      ),
    );
  }
}
