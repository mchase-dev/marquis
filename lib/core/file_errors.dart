/// Thrown when a file does not exist at the given path.
class FileNotFoundException implements Exception {
  final String path;
  const FileNotFoundException(this.path);

  @override
  String toString() => 'File not found: $path';
}

/// Thrown when the OS denies read or write access.
class FilePermissionException implements Exception {
  final String path;
  const FilePermissionException(this.path);

  @override
  String toString() => 'Permission denied: $path';
}

/// Thrown when a write fails due to insufficient disk space.
class DiskFullException implements Exception {
  final String path;
  const DiskFullException(this.path);

  @override
  String toString() => 'Disk full — could not write: $path';
}

/// Thrown when a file cannot be decoded as UTF-8.
/// [fallbackEncoding] indicates the encoding used instead (e.g. "latin1").
class FileEncodingException implements Exception {
  final String path;
  final String fallbackEncoding;
  const FileEncodingException(this.path, {this.fallbackEncoding = 'latin1'});

  @override
  String toString() =>
      'Encoding error for $path (fell back to $fallbackEncoding)';
}
