import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/providers/view_mode_provider.dart';

/// Slim toolbar at the top of the app [DD §5 — Toolbar]
class AppToolbar extends ConsumerWidget {
  const AppToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewMode = ref.watch(viewModeProvider);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Edit mode toggle [DD §10 — Toggling Edit Mode]
          IconButton(
            icon: Icon(
              viewMode == ViewMode.viewerOnly
                  ? Icons.edit_outlined
                  : Icons.edit,
              size: 18,
            ),
            tooltip: 'Toggle Edit Mode (Ctrl+E)',
            onPressed: () {
              ref.read(viewModeProvider.notifier).toggleEdit();
            },
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          // Command palette — placeholder [DD §5, Phase 5]
          IconButton(
            icon: const Icon(Icons.terminal_outlined, size: 18),
            tooltip: 'Command Palette (Ctrl+/)',
            onPressed: () {},
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          // View mode selector [DD §10 — Layout Modes]
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<ViewMode>(
              segments: const [
                ButtonSegment(
                  value: ViewMode.viewerOnly,
                  icon: Icon(Icons.visibility_outlined, size: 16),
                  tooltip: 'Viewer Only',
                ),
                ButtonSegment(
                  value: ViewMode.split,
                  icon: Icon(Icons.vertical_split_outlined, size: 16),
                  tooltip: 'Split View',
                ),
                ButtonSegment(
                  value: ViewMode.editorOnly,
                  icon: Icon(Icons.edit_note_outlined, size: 16),
                  tooltip: 'Editor Only',
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (selected) {
                ref.read(viewModeProvider.notifier).setMode(selected.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
