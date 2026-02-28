import 'package:flutter_test/flutter_test.dart';
import '../helpers/fixtures.dart';

void main() {
  group('DocumentState', () {
    group('isDirty', () {
      test('false when content matches lastSavedContent', () {
        final doc = makeDocumentState(
          content: 'hello',
          lastSavedContent: 'hello',
        );
        expect(doc.isDirty, isFalse);
      });

      test('true when content differs from lastSavedContent', () {
        final doc = makeDocumentState(
          content: 'hello world',
          lastSavedContent: 'hello',
        );
        expect(doc.isDirty, isTrue);
      });

      test('false when both content and lastSavedContent are empty', () {
        final doc = makeDocumentState(
          content: '',
          lastSavedContent: null,
        );
        expect(doc.isDirty, isFalse);
      });

      test('true when lastSavedContent is null and content is non-empty', () {
        final doc = makeDocumentState(
          content: '# Hello',
          lastSavedContent: null,
        );
        expect(doc.isDirty, isTrue);
      });
    });

    group('isUntitled', () {
      test('true when filePath is null', () {
        final doc = makeDocumentState(filePath: null);
        expect(doc.isUntitled, isTrue);
      });

      test('false when filePath is set', () {
        final doc = makeDocumentState(filePath: '/tmp/test.md');
        expect(doc.isUntitled, isFalse);
      });
    });

    group('isHelpDocument', () {
      test('true when helpTitle is set', () {
        final doc = makeDocumentState(helpTitle: 'User Guide');
        expect(doc.isHelpDocument, isTrue);
      });

      test('false when helpTitle is null', () {
        final doc = makeDocumentState();
        expect(doc.isHelpDocument, isFalse);
      });
    });

    group('displayName', () {
      test('returns helpTitle if set', () {
        final doc = makeDocumentState(helpTitle: 'User Guide');
        expect(doc.displayName, 'User Guide');
      });

      test('returns filename from filePath with forward slashes', () {
        final doc = makeDocumentState(filePath: '/home/user/docs/readme.md');
        expect(doc.displayName, 'readme.md');
      });

      test('returns filename from filePath with backslashes', () {
        final doc =
            makeDocumentState(filePath: r'C:\Users\user\docs\readme.md');
        expect(doc.displayName, 'readme.md');
      });

      test('returns Untitled when no path and no helpTitle', () {
        final doc = makeDocumentState();
        expect(doc.displayName, 'Untitled');
      });

      test('helpTitle takes priority over filePath', () {
        final doc = makeDocumentState(
          helpTitle: 'Guide',
          filePath: '/tmp/guide.md',
        );
        expect(doc.displayName, 'Guide');
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final doc = makeDocumentState(
          id: 'abc',
          content: 'test',
          filePath: '/tmp/file.md',
          encoding: 'utf-8',
        );
        final copy = doc.copyWith(content: 'updated');
        expect(copy.id, 'abc');
        expect(copy.content, 'updated');
        expect(copy.filePath, '/tmp/file.md');
        expect(copy.encoding, 'utf-8');
      });

      test('overrides specified fields', () {
        final doc = makeDocumentState(content: 'old');
        final copy = doc.copyWith(content: 'new', isEditMode: true);
        expect(copy.content, 'new');
        expect(copy.isEditMode, isTrue);
      });

      test('clearFilePath nulls filePath', () {
        final doc = makeDocumentState(filePath: '/tmp/file.md');
        final copy = doc.copyWith(clearFilePath: true);
        expect(copy.filePath, isNull);
      });

      test('clearLastSavedContent nulls lastSavedContent', () {
        final doc = makeDocumentState(lastSavedContent: 'saved');
        final copy = doc.copyWith(clearLastSavedContent: true);
        expect(copy.lastSavedContent, isNull);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final now = DateTime(2025, 1, 1);
        final a = makeDocumentState(
          id: 'x',
          content: 'hello',
          filePath: '/tmp/a.md',
          lastModified: now,
        );
        final b = makeDocumentState(
          id: 'x',
          content: 'hello',
          filePath: '/tmp/a.md',
          lastModified: now,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when content differs', () {
        final a = makeDocumentState(content: 'hello');
        final b = makeDocumentState(content: 'world');
        expect(a, isNot(equals(b)));
      });

      test('not equal when id differs', () {
        final a = makeDocumentState(id: 'a');
        final b = makeDocumentState(id: 'b');
        expect(a, isNot(equals(b)));
      });

      test('not equal when filePath differs', () {
        final a = makeDocumentState(filePath: '/tmp/a.md');
        final b = makeDocumentState(filePath: '/tmp/b.md');
        expect(a, isNot(equals(b)));
      });
    });
  });
}
