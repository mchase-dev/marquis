import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:marquis/models/command_item.dart';
import 'package:marquis/widgets/command_palette/command_data.dart';

/// Modal command palette overlay [DD §11 — UI]
class CommandPalette extends StatefulWidget {
  final List<CommandItem> commands;
  final ValueChanged<CommandItem> onSelect;
  final VoidCallback onClose;

  const CommandPalette({
    super.key,
    required this.commands,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;
  List<CommandItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.commands;
    _controller.addListener(_onFilterChanged);
    // Autofocus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final query = _controller.text;
    setState(() {
      _filtered = widget.commands
          .where((cmd) => CommandData.matchesFilter(cmd, query))
          .toList();
      _selectedIndex = 0;
    });
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, _filtered.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, _filtered.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_filtered.isNotEmpty) {
        widget.onSelect(_filtered[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Scrim
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black26),
        ),
        // Palette positioned near top center [DD §11 — UI]
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.surfaceContainer,
              child: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search input
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: _onKeyEvent,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Type a command or markdown snippet...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    // Results list
                    if (_filtered.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          padding: const EdgeInsets.only(bottom: 4),
                          itemBuilder: (context, index) {
                            final item = _filtered[index];
                            final isSelected = index == _selectedIndex;

                            return _CommandListItem(
                              item: item,
                              isSelected: isSelected,
                              onTap: () => widget.onSelect(item),
                              onHover: () {
                                setState(() => _selectedIndex = index);
                              },
                            );
                          },
                        ),
                      ),
                    if (_filtered.isEmpty && _controller.text.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No matching commands',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual command item in the palette list [DD §11 — UI: icon, name, description, shortcut]
class _CommandListItem extends StatelessWidget {
  final CommandItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const _CommandListItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                item.icon ?? Icons.code,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (item.shortcut != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.shortcut!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
