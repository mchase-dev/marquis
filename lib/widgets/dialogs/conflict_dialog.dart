import 'package:flutter/material.dart';

/// Result of the external-change conflict dialog [DD §15 — Case 2]
enum ConflictDialogResult { reload, keepLocal }

/// Shown when a file has been modified externally while it has local changes
class ConflictDialog extends StatelessWidget {
  final String fileName;

  const ConflictDialog({super.key, required this.fileName});

  static Future<ConflictDialogResult?> show(
    BuildContext context, {
    required String fileName,
  }) {
    return showDialog<ConflictDialogResult>(
      context: context,
      builder: (_) => ConflictDialog(fileName: fileName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('File changed externally'),
      content: Text(
        '"$fileName" has been modified outside of Marquis.\n'
        'Your local changes will be lost if you reload.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, ConflictDialogResult.keepLocal),
          child: const Text('Keep My Changes'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, ConflictDialogResult.reload),
          child: const Text('Reload from Disk'),
        ),
      ],
    );
  }
}
