import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:marquis/core/constants.dart';
import 'package:marquis/core/file_errors.dart';

/// Size threshold for large-file warning (10 MB) [DD §24]
const _largeFileThreshold = 10 * 1024 * 1024;

/// File I/O operations [DD §7, §23, §24]
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

  /// Read a file from disk [DD §7 — Document Lifecycle step 2, DD §24]
  ///
  /// Returns content, lastModified, whether file is large (>10MB), and
  /// whether a fallback encoding was used.
  Future<ReadFileResult> readFile(String path) async {
    final file = File(path);

    // Check existence
    if (!await file.exists()) {
      throw FileNotFoundException(path);
    }

    // Check size for large file warning
    final length = await file.length();
    final isLargeFile = length > _largeFileThreshold;

    // Try UTF-8 first, fall back to Latin-1 on encoding error
    String content;
    String encoding = 'utf-8';
    try {
      content = await file.readAsString(encoding: utf8);
    } on FileSystemException catch (e) {
      // Classify OS-level errors (permission denied)
      if (_isPermissionError(e)) {
        throw FilePermissionException(path);
      }
      // Encoding error — retry with Latin-1
      try {
        content = await file.readAsString(encoding: latin1);
        encoding = 'latin1';
      } on FileSystemException catch (e2) {
        if (_isPermissionError(e2)) {
          throw FilePermissionException(path);
        }
        rethrow;
      }
    } on FormatException {
      // readAsString can throw FormatException for invalid UTF-8
      try {
        content = await file.readAsString(encoding: latin1);
        encoding = 'latin1';
      } on FileSystemException catch (e) {
        if (_isPermissionError(e)) {
          throw FilePermissionException(path);
        }
        rethrow;
      }
    }

    final stat = await file.stat();
    return ReadFileResult(
      content: content,
      lastModified: stat.modified,
      isLargeFile: isLargeFile,
      encoding: encoding,
    );
  }

  /// Write content to a file [DD §7 — Document Lifecycle step 4, DD §24]
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    try {
      await file.writeAsString(content);
    } on FileSystemException catch (e) {
      if (_isPermissionError(e)) {
        throw FilePermissionException(path);
      }
      if (_isDiskFullError(e)) {
        throw DiskFullException(path);
      }
      rethrow;
    }
  }

  /// Check if a file exists
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Classify a FileSystemException as permission-denied based on OS error code.
  static bool _isPermissionError(FileSystemException e) {
    final code = e.osError?.errorCode;
    if (code == null) return false;
    // EACCES (13) on Linux/macOS, ERROR_ACCESS_DENIED (5) on Windows
    return code == 13 || code == 5;
  }

  /// Classify a FileSystemException as disk-full based on OS error code.
  static bool _isDiskFullError(FileSystemException e) {
    final code = e.osError?.errorCode;
    if (code == null) return false;
    // ENOSPC (28) on Linux/macOS, ERROR_DISK_FULL (112) on Windows
    return code == 28 || code == 112;
  }
}

/// Result of [FileService.readFile] with metadata about encoding and size.
class ReadFileResult {
  final String content;
  final DateTime lastModified;
  final bool isLargeFile;
  final String encoding;

  const ReadFileResult({
    required this.content,
    required this.lastModified,
    this.isLargeFile = false,
    this.encoding = 'utf-8',
  });
}
