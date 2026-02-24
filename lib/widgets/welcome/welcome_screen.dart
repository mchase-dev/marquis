import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/core/constants.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/providers/tab_manager_provider.dart';

/// Welcome screen shown when no tabs are open [DD §6 — Empty State]
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(preferencesProvider).value;
    final recentFiles = prefs?.general.recentFiles ?? [];

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App name
            Text(
              AppConstants.appFullName,
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The Noble Markdown Editor',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.note_add_outlined,
                  label: 'New File',
                  shortcut: 'Ctrl+N',
                  onPressed: () =>
                      ref.read(tabManagerProvider.notifier).newFile(),
                ),
                const SizedBox(width: 16),
                _ActionButton(
                  icon: Icons.folder_open_outlined,
                  label: 'Open File',
                  shortcut: 'Ctrl+O',
                  onPressed: () =>
                      ref.read(tabManagerProvider.notifier).openFileDialog(),
                ),
              ],
            ),
            // Recent files
            if (recentFiles.isNotEmpty) ...[
              const SizedBox(height: 40),
              Text(
                'Recent Files',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: recentFiles.map((path) {
                    final fileName = path.split(RegExp(r'[/\\]')).last;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        fileName,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        path,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        // Check if file still exists
                        if (await File(path).exists()) {
                          ref
                              .read(tabManagerProvider.notifier)
                              .openFile(path);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('File not found: $fileName')),
                            );
                          }
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            // Shortcut hints
            const SizedBox(height: 40),
            _ShortcutHints(),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String shortcut;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(label),
          const SizedBox(height: 4),
          Text(
            shortcut,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutHints extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        Text('Ctrl+N  New File  |  Ctrl+O  Open File  |  Ctrl+/  Command Palette',
            style: style),
      ],
    );
  }
}
