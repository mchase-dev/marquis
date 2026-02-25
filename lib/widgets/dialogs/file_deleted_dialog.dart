import 'package:flutter/material.dart';

/// Result of the file-deleted dialog [DD §15 — Case 3]
enum FileDeletedResult { saveToOriginal, saveAs, closeTab }

/// Shown when a file has been deleted from disk while open
class FileDeletedDialog extends StatelessWidget {
  final String fileName;

  const FileDeletedDialog({super.key, required this.fileName});

  static Future<FileDeletedResult?> show(
    BuildContext context, {
    required String fileName,
  }) {
    return showDialog<FileDeletedResult>(
      context: context,
      builder: (_) => FileDeletedDialog(fileName: fileName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('File deleted'),
      content: Text('"$fileName" has been deleted from disk.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, FileDeletedResult.closeTab),
          child: const Text('Close Tab'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, FileDeletedResult.saveAs),
          child: const Text('Save As...'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, FileDeletedResult.saveToOriginal),
          child: const Text('Save to Original Location'),
        ),
      ],
    );
  }
}
