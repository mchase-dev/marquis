import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Individual tab widget
class TabItem extends StatelessWidget {
  final String tabId;
  final String displayName;
  final bool isDirty;
  final bool isActive;
  final bool isConflict;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const TabItem({
    super.key,
    required this.tabId,
    required this.displayName,
    required this.isDirty,
    required this.isActive,
    required this.isConflict,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Listener(
      // Middle-click to close
      onPointerDown: (event) {
        if (event.buttons == kMiddleMouseButton) {
          onClose();
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 100,
            maxWidth: 200,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: isActive ? accentColor : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: theme.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dirty dot or conflict icon
              if (isConflict)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                )
              else if (isDirty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '●',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              // Filename
              Flexible(
                child: Text(
                  displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              // Close button
              const SizedBox(width: 4),
              SizedBox(
                width: 20,
                height: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  padding: EdgeInsets.zero,
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
