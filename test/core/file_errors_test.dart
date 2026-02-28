import 'package:flutter_test/flutter_test.dart';
import 'package:marquis/core/file_errors.dart';

void main() {
  group('FileNotFoundException', () {
    test('stores path', () {
      const e = FileNotFoundException('/tmp/missing.md');
      expect(e.path, '/tmp/missing.md');
    });

    test('toString includes path', () {
      const e = FileNotFoundException('/tmp/missing.md');
      expect(e.toString(), 'File not found: /tmp/missing.md');
    });
  });

  group('FilePermissionException', () {
    test('stores path', () {
      const e = FilePermissionException('/etc/secret');
      expect(e.path, '/etc/secret');
    });

    test('toString includes path', () {
      const e = FilePermissionException('/etc/secret');
      expect(e.toString(), 'Permission denied: /etc/secret');
    });
  });

  group('DiskFullException', () {
    test('stores path', () {
      const e = DiskFullException('/tmp/big.md');
      expect(e.path, '/tmp/big.md');
    });

    test('toString includes path', () {
      const e = DiskFullException('/tmp/big.md');
      expect(e.toString(), contains('/tmp/big.md'));
    });
  });

  group('FileEncodingException', () {
    test('stores path and default fallback encoding', () {
      const e = FileEncodingException('/tmp/garbled.md');
      expect(e.path, '/tmp/garbled.md');
      expect(e.fallbackEncoding, 'latin1');
    });

    test('stores custom fallback encoding', () {
      const e = FileEncodingException('/tmp/garbled.md',
          fallbackEncoding: 'windows-1252');
      expect(e.fallbackEncoding, 'windows-1252');
    });

    test('toString includes path and fallback encoding', () {
      const e = FileEncodingException('/tmp/garbled.md',
          fallbackEncoding: 'windows-1252');
      final str = e.toString();
      expect(str, contains('/tmp/garbled.md'));
      expect(str, contains('windows-1252'));
    });

    test('toString with default fallback encoding mentions latin1', () {
      const e = FileEncodingException('/tmp/garbled.md');
      expect(e.toString(), contains('latin1'));
    });
  });
}
