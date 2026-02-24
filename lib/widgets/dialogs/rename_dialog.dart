import 'dart:io';

import 'package:flutter/material.dart';

/// Dialog for renaming a file [DD §12 — Rename File Behavior]
class RenameDialog extends StatefulWidget {
  final String currentFileName;
  final String currentFilePath;

  const RenameDialog({
    super.key,
    required this.currentFileName,
    required this.currentFilePath,
  });

  /// Shows the rename dialog and returns the new file path if renamed,
  /// or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String currentFileName,
    required String currentFilePath,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => RenameDialog(
        currentFileName: currentFileName,
        currentFilePath: currentFilePath,
      ),
    );
  }

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentFileName);
    // Select just the name without extension
    final dotIndex = widget.currentFileName.lastIndexOf('.');
    if (dotIndex > 0) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: dotIndex,
      );
    } else {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.currentFileName.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _rename() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      setState(() => _error = 'File name cannot be empty');
      return;
    }
    if (newName == widget.currentFileName) {
      Navigator.of(context).pop(null);
      return;
    }

    // Build new path (same directory, new name) [DD §12 — step 3]
    final dir = File(widget.currentFilePath).parent.path;
    final newPath = '$dir${Platform.pathSeparator}$newName';

    // Check if name already exists [DD §12 — step 6]
    if (await File(newPath).exists()) {
      setState(() => _error = 'A file with that name already exists');
      return;
    }

    try {
      await File(widget.currentFilePath).rename(newPath);
      if (mounted) Navigator.of(context).pop(newPath);
    } catch (e) {
      setState(() => _error = 'Rename failed: ${e.toString().split(':').last.trim()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'File name',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _rename(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _rename,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
