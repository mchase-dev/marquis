import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:marquis/core/constants.dart';

/// File I/O operations [DD §7, §23]
class FileService {
  /// Show a native file open dialog and return the selected path(s) [DD §23]
  Future<List<String>?> pickFilesToOpen() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.markdownExtensions,
      allowMultiple: true,
    );
    return result?.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
  }

  /// Show a native Save As dialog and return the selected path
  Future<String?> pickSaveAsPath({String? defaultFileName}) async {
    return await FilePicker.platform.saveFile(
      dialogTitle: 'Save As',
      fileName: defaultFileName ?? 'Untitled.md',
      type: FileType.custom,
      allowedExtensions: AppConstants.markdownExtensions,
    );
  }

  /// Read a file from disk [DD §7 — Document Lifecycle step 2]
  Future<({String content, DateTime lastModified})> readFile(
      String path) async {
    final file = File(path);
    final content = await file.readAsString();
    final stat = await file.stat();
    return (content: content, lastModified: stat.modified);
  }

  /// Write content to a file [DD §7 — Document Lifecycle step 4]
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  /// Check if a file exists
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }
}
