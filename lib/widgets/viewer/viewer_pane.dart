import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/theme/viewer_theme.dart';
import 'package:marquis/widgets/viewer/viewer_find_bar.dart';

/// Error boundary widget that catches rendering errors and shows fallback [DD §24]
class _MarkdownErrorBoundary extends StatefulWidget {
  final Widget child;
  final String rawContent;

  const _MarkdownErrorBoundary({
    required this.child,
    required this.rawContent,
  });

  @override
  State<_MarkdownErrorBoundary> createState() => _MarkdownErrorBoundaryState();
}

class _MarkdownErrorBoundaryState extends State<_MarkdownErrorBoundary> {
  bool _hasError = false;

  @override
  void didUpdateWidget(_MarkdownErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state when content changes — new content might render fine
    if (oldWidget.rawContent != widget.rawContent) {
      _hasError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallback(context);
    }

    // Wrap the child in an ErrorWidget.builder override scoped to this subtree
    return _ErrorCatcher(
      onError: () {
        if (mounted) setState(() => _hasError = true);
      },
      child: widget.child,
    );
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.errorContainer,
          child: Text(
            'Markdown rendering error — showing raw text',
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              widget.rawContent,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Catches errors from a child widget subtree during build/layout/paint.
class _ErrorCatcher extends StatefulWidget {
  final VoidCallback onError;
  final Widget child;

  const _ErrorCatcher({required this.onError, required this.child});

  @override
  State<_ErrorCatcher> createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<_ErrorCatcher> {
  @override
  Widget build(BuildContext context) {
    // Use a Builder so that ErrorWidget.builder override applies to the subtree
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Schedule the callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onError();
      });
      return const SizedBox.shrink();
    };
    return widget.child;
  }

  @override
  void dispose() {
    // Restore default error widget builder
    ErrorWidget.builder = ErrorWidget.new;
    super.dispose();
  }
}

/// Rendered Markdown viewer [DD §9]
class ViewerPane extends ConsumerStatefulWidget {
  final String content;
  final String? filePath;
  final ScrollController? scrollController;

  const ViewerPane({
    super.key,
    required this.content,
    this.filePath,
    this.scrollController,
  });

  @override
  ConsumerState<ViewerPane> createState() => ViewerPaneState();
}

class ViewerPaneState extends ConsumerState<ViewerPane> {
  bool _showFindBar = false;

  /// Open viewer find bar (Ctrl+F in viewer context) [DD §16]
  void showFind() {
    setState(() => _showFindBar = true);
  }

  /// Close viewer find bar
  void closeFindBar() {
    setState(() => _showFindBar = false);
  }

  void _scrollToFraction(double fraction) {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    final target = fraction * controller.position.maxScrollExtent;
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(preferencesProvider).value;
    final fontSize = prefs?.appearance.viewerFontSize.toDouble() ?? 16;
    final zoomLevel = prefs?.appearance.zoomLevel ?? 100;
    final effectiveFontSize = fontSize * zoomLevel / 100;

    final config = isDark
        ? ViewerTheme.dark(fontSize: effectiveFontSize)
        : ViewerTheme.light(fontSize: effectiveFontSize);

    return Column(
      children: [
        if (_showFindBar)
          ViewerFindBar(
            content: widget.content,
            onScrollToMatch: _scrollToFraction,
            onClose: closeFindBar,
          ),
        Expanded(
          child: widget.content.isEmpty
              ? Center(
                  child: Text(
                    'Empty document',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : _MarkdownErrorBoundary(
                  rawContent: widget.content,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SingleChildScrollView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                      child: MarkdownBlock(
                        data: widget.content,
                        config: config,
                        selectable: true,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
