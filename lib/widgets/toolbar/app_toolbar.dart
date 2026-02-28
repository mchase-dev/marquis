import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/providers/view_mode_provider.dart';

/// Slim toolbar at the top of the app
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
          const Spacer(),
          // View mode selector
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
