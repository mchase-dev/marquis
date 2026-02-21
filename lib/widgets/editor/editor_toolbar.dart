import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import 'package:marquis/services/formatting_service.dart';

/// Slim toolbar with formatting buttons shown above the editor [DD §8 — Editor Toolbar]
class EditorToolbar extends StatelessWidget {
  final CodeLineEditingController controller;

  const EditorToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: const Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            tooltip: 'Bold (Ctrl+B)',
            onPressed: () => FormattingService.bold(controller),
          ),
          _ToolbarButton(
            icon: const Text('I', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
            tooltip: 'Italic (Ctrl+I)',
            onPressed: () => FormattingService.italic(controller),
          ),
          _ToolbarButton(
            icon: const Text('S', style: TextStyle(decoration: TextDecoration.lineThrough, fontSize: 14)),
            tooltip: 'Strikethrough (Alt+S)',
            onPressed: () => FormattingService.strikethrough(controller),
          ),
          _ToolbarButton(
            icon: const Icon(Icons.code, size: 16),
            tooltip: 'Inline Code',
            onPressed: () => FormattingService.inlineCode(controller),
          ),
          _divider(context),
          _ToolbarButton(
            icon: const Icon(Icons.link, size: 16),
            tooltip: 'Link (Ctrl+K)',
            onPressed: () => FormattingService.link(controller),
          ),
          _ToolbarButton(
            icon: const Icon(Icons.image_outlined, size: 16),
            tooltip: 'Image',
            onPressed: () => FormattingService.image(controller),
          ),
          _divider(context),
          _ToolbarButton(
            icon: const Icon(Icons.format_list_bulleted, size: 16),
            tooltip: 'Bullet List (Ctrl+Shift+8)',
            onPressed: () => FormattingService.unorderedList(controller),
          ),
          _ToolbarButton(
            icon: const Icon(Icons.format_list_numbered, size: 16),
            tooltip: 'Numbered List (Ctrl+Shift+9)',
            onPressed: () => FormattingService.orderedList(controller),
          ),
          _ToolbarButton(
            icon: const Icon(Icons.check_box_outlined, size: 16),
            tooltip: 'Task List (Ctrl+Shift+X)',
            onPressed: () => FormattingService.taskList(controller),
          ),
          _divider(context),
          _ToolbarButton(
            icon: const Icon(Icons.format_quote, size: 16),
            tooltip: 'Block Quote (Ctrl+Shift+.)',
            onPressed: () => FormattingService.blockQuote(controller),
          ),
          _ToolbarButton(
            icon: const Icon(Icons.data_object, size: 16),
            tooltip: 'Code Block (Ctrl+Shift+K)',
            onPressed: () => FormattingService.codeBlock(controller),
          ),
          _ToolbarButton(
            icon: const Icon(Icons.table_chart_outlined, size: 16),
            tooltip: 'Table',
            onPressed: () => FormattingService.table(controller),
          ),
          _ToolbarButton(
            icon: const Icon(Icons.horizontal_rule, size: 16),
            tooltip: 'Horizontal Rule (Ctrl+Shift+-)',
            onPressed: () => FormattingService.horizontalRule(controller),
          ),
          _divider(context),
          // Heading dropdown [DD §8 — H▼ heading dropdown]
          _HeadingDropdown(controller: controller),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Container(
        width: 1,
        color: Theme.of(context).dividerColor,
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: SizedBox(width: 24, height: 24, child: Center(child: icon)),
        ),
      ),
    );
  }
}

class _HeadingDropdown extends StatelessWidget {
  final CodeLineEditingController controller;

  const _HeadingDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Heading Level (1–6)',
      offset: const Offset(0, 36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('H', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            )),
            Icon(Icons.arrow_drop_down, size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => List.generate(6, (i) {
        final level = i + 1;
        return PopupMenuItem(
          value: level,
          child: Text('Heading $level', style: TextStyle(
            fontSize: 16.0 - level,
            fontWeight: FontWeight.bold,
          )),
        );
      }),
      onSelected: (level) => FormattingService.heading(controller, level),
    );
  }
}
