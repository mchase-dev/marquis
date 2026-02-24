import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/theme/viewer_theme.dart';

/// Rendered Markdown viewer [DD §9]
class ViewerPane extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(preferencesProvider).value;
    final fontSize = prefs?.appearance.viewerFontSize.toDouble() ?? 16;
    final zoomLevel = prefs?.appearance.zoomLevel ?? 100;
    final effectiveFontSize = fontSize * zoomLevel / 100;

    final config = isDark
        ? ViewerTheme.dark(fontSize: effectiveFontSize)
        : ViewerTheme.light(fontSize: effectiveFontSize);

    if (content.isEmpty) {
      return Center(
        child: Text(
          'Empty document',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    // Use MarkdownBlock (non-scrollable) inside our own ScrollView
    // so we can control scrolling for scroll sync [DD §10]
    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
        child: MarkdownBlock(
          data: content,
          config: config,
          selectable: true,
        ),
      ),
    );
  }
}
