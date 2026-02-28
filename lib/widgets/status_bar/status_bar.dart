import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/providers/cursor_position_provider.dart';
import 'package:marquis/providers/document_provider.dart';
import 'package:marquis/providers/hovered_link_provider.dart';
import 'package:marquis/providers/save_status_provider.dart';
import 'package:marquis/providers/view_mode_provider.dart';

/// Bottom status bar showing document info
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeDoc = ref.watch(activeDocumentProvider);
    final saveStatus = ref.watch(saveStatusProvider);
    final viewMode = ref.watch(viewModeProvider);
    final cursorPos = ref.watch(cursorPositionProvider);
    final hoveredLink = ref.watch(hoveredLinkProvider);

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    // Show editor info when editor is visible
    final showEditorInfo = activeDoc != null &&
        !activeDoc.isReadOnly &&
        (viewMode == ViewMode.split || viewMode == ViewMode.editorOnly);

    // Word count
    String? wordCount;
    if (activeDoc != null && activeDoc.content.isNotEmpty) {
      final count = activeDoc.content
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      wordCount = '$count ${count == 1 ? 'word' : 'words'}';
    }

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (hoveredLink != null)
            Expanded(
              child: Text(
                hoveredLink,
                style: labelStyle?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          else ...[
            Text(saveStatus.label, style: labelStyle),
            const Spacer(),
          ],
          if (wordCount != null) ...[
            Text(wordCount, style: labelStyle),
            _separator(theme),
          ],
          if (showEditorInfo) ...[
            Text('Ln ${cursorPos.line}, Col ${cursorPos.column}',
                style: labelStyle),
            _separator(theme),
          ],
          Text(activeDoc?.encoding.toUpperCase() ?? 'UTF-8', style: labelStyle),
          _separator(theme),
          Text('Markdown', style: labelStyle),
        ],
      ),
    );
  }

  Widget _separator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '|',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
