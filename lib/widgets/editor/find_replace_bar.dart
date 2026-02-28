import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

/// Find & Replace bar for the editor
class FindReplaceBar extends StatefulWidget {
  final CodeFindController findController;
  final bool showReplace;
  final VoidCallback onClose;

  const FindReplaceBar({
    super.key,
    required this.findController,
    required this.showReplace,
    required this.onClose,
  });

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  bool _caseSensitive = false;
  bool _useRegex = false;

  @override
  void initState() {
    super.initState();
    widget.findController.addListener(_onFindChanged);
    // Sync initial state from controller
    final value = widget.findController.value;
    if (value != null) {
      _caseSensitive = value.option.caseSensitive;
      _useRegex = value.option.regex;
    }
    // Focus the find input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.findController.focusOnFindInput();
    });
  }

  @override
  void dispose() {
    widget.findController.removeListener(_onFindChanged);
    super.dispose();
  }

  void _onFindChanged() {
    if (mounted) setState(() {});
  }

  String _matchInfo() {
    final value = widget.findController.value;
    if (value == null) return '';
    final result = value.result;
    if (result == null || result.matches.isEmpty) {
      if (value.option.pattern.isEmpty) return '';
      return 'No results';
    }
    return '${result.index + 1} of ${result.matches.length}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerLow;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFindRow(theme),
          if (widget.showReplace) ...[
            const SizedBox(height: 4),
            _buildReplaceRow(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildFindRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent || event is KeyRepeatEvent) {
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  _close();
                } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                  if (HardwareKeyboard.instance.isShiftPressed) {
                    widget.findController.previousMatch();
                  } else {
                    widget.findController.nextMatch();
                  }
                }
              }
            },
            child: TextField(
              controller: widget.findController.findInputController,
              focusNode: widget.findController.findInputFocusNode,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Find',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _ToggleButton(
          tooltip: 'Match Case',
          icon: 'Aa',
          isActive: _caseSensitive,
          onPressed: () {
            widget.findController.toggleCaseSensitive();
            setState(() => _caseSensitive = !_caseSensitive);
          },
        ),
        _ToggleButton(
          tooltip: 'Use Regular Expression',
          icon: '.*',
          isActive: _useRegex,
          onPressed: () {
            widget.findController.toggleRegex();
            setState(() => _useRegex = !_useRegex);
          },
        ),
        const SizedBox(width: 4),
        Text(
          _matchInfo(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        _IconBtn(
          tooltip: 'Previous Match',
          icon: Icons.keyboard_arrow_up,
          onPressed: () => widget.findController.previousMatch(),
        ),
        _IconBtn(
          tooltip: 'Next Match',
          icon: Icons.keyboard_arrow_down,
          onPressed: () => widget.findController.nextMatch(),
        ),
        _IconBtn(
          tooltip: 'Close',
          icon: Icons.close,
          onPressed: _close,
        ),
      ],
    );
  }

  Widget _buildReplaceRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.findController.replaceInputController,
            focusNode: widget.findController.replaceInputFocusNode,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Replace',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _SmallTextButton(
          label: 'Replace',
          onPressed: () => widget.findController.replaceMatch(),
        ),
        const SizedBox(width: 4),
        _SmallTextButton(
          label: 'Replace All',
          onPressed: () => widget.findController.replaceAllMatches(),
        ),
      ],
    );
  }

  void _close() {
    widget.findController.close();
    widget.onClose();
  }
}

class _ToggleButton extends StatelessWidget {
  final String tooltip;
  final String icon;
  final bool isActive;
  final VoidCallback onPressed;

  const _ToggleButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            icon,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _IconBtn({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _SmallTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SmallTextButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }
}
