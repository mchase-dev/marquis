import 'package:flutter/material.dart';

/// Result of a save prompt dialog [DD §5 — Close behavior]
enum SaveDialogResult { save, discard, cancel }

/// "Save changes before closing?" dialog [DD §5, §7]
class SaveDialog extends StatelessWidget {
  final int fileCount;
  final String? fileName;

  const SaveDialog({
    super.key,
    this.fileCount = 1,
    this.fileName,
  });

  /// Show for a single file
  static Future<SaveDialogResult?> showSingle(
    BuildContext context, {
    required String fileName,
  }) {
    return showDialog<SaveDialogResult>(
      context: context,
      builder: (_) => SaveDialog(fileName: fileName),
    );
  }

  /// Show for multiple files
  static Future<SaveDialogResult?> showMultiple(
    BuildContext context, {
    required int fileCount,
  }) {
    return showDialog<SaveDialogResult>(
      context: context,
      builder: (_) => SaveDialog(fileCount: fileCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = fileCount > 1
        ? 'Do you want to save changes to $fileCount files before closing?'
        : 'Do you want to save changes to "${fileName ?? "this file"}" before closing?';

    return AlertDialog(
      title: const Text('Save changes?'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, SaveDialogResult.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, SaveDialogResult.discard),
          child: const Text("Don't Save"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, SaveDialogResult.save),
          child: Text(fileCount > 1 ? 'Save All' : 'Save'),
        ),
      ],
    );
  }
}
