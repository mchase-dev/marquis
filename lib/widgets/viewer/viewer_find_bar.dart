import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Find bar for the viewer pane — search only, no replace
///
/// Searches raw markdown text and scrolls to approximate match positions
/// using proportional scrolling.
class ViewerFindBar extends StatefulWidget {
  final String content;
  final void Function(double fraction) onScrollToMatch;
  final VoidCallback onClose;

  const ViewerFindBar({
    super.key,
    required this.content,
    required this.onScrollToMatch,
    required this.onClose,
  });

  @override
  State<ViewerFindBar> createState() => _ViewerFindBarState();
}

class _ViewerFindBarState extends State<ViewerFindBar> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _caseSensitive = false;
  bool _useRegex = false;

  List<Match> _matches = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ViewerFindBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content) {
      _updateMatches();
    }
  }

  void _onSearchChanged() {
    _updateMatches();
  }

  void _updateMatches() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _matches = [];
        _currentIndex = 0;
      });
      return;
    }

    try {
      final Pattern pattern;
      if (_useRegex) {
        pattern = RegExp(
          query,
          caseSensitive: _caseSensitive,
        );
      } else {
        pattern = RegExp(
          RegExp.escape(query),
          caseSensitive: _caseSensitive,
        );
      }
      final matches = pattern.allMatches(widget.content).toList();
      setState(() {
        _matches = matches;
        _currentIndex = matches.isEmpty ? 0 : _currentIndex.clamp(0, matches.length - 1);
      });
      if (matches.isNotEmpty) {
        _scrollToCurrentMatch();
      }
    } catch (_) {
      // Invalid regex — clear matches
      setState(() {
        _matches = [];
        _currentIndex = 0;
      });
    }
  }

  void _scrollToCurrentMatch() {
    if (_matches.isEmpty || widget.content.isEmpty) return;
    final match = _matches[_currentIndex];
    final fraction = match.start / widget.content.length;
    widget.onScrollToMatch(fraction.clamp(0.0, 1.0));
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _matches.length;
    });
    _scrollToCurrentMatch();
  }

  void _previousMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _matches.length) % _matches.length;
    });
    _scrollToCurrentMatch();
  }

  String _matchInfo() {
    if (_searchController.text.isEmpty) return '';
    if (_matches.isEmpty) return 'No results';
    return '${_currentIndex + 1} of ${_matches.length}';
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
      child: Row(
        children: [
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent || event is KeyRepeatEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    widget.onClose();
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      _previousMatch();
                    } else {
                      _nextMatch();
                    }
                  }
                }
              },
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Find in viewer',
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
              setState(() => _caseSensitive = !_caseSensitive);
              _updateMatches();
            },
          ),
          _ToggleButton(
            tooltip: 'Use Regular Expression',
            icon: '.*',
            isActive: _useRegex,
            onPressed: () {
              setState(() => _useRegex = !_useRegex);
              _updateMatches();
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
            onPressed: _previousMatch,
          ),
          _IconBtn(
            tooltip: 'Next Match',
            icon: Icons.keyboard_arrow_down,
            onPressed: _nextMatch,
          ),
          _IconBtn(
            tooltip: 'Close',
            icon: Icons.close,
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
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
