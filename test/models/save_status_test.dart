import 'package:flutter_test/flutter_test.dart';
import 'package:marquis/models/save_status.dart';

void main() {
  group('SaveStatus', () {
    test('saved has expected label', () {
      expect(SaveStatus.saved.label, 'Saved');
    });

    test('saving has expected label', () {
      expect(SaveStatus.saving.label, 'Saving...');
    });

    test('unsaved has expected label', () {
      expect(SaveStatus.unsaved.label, 'Unsaved changes');
    });

    test('disabled has expected label', () {
      expect(SaveStatus.disabled.label, 'Auto-save: off');
    });

    test('none has expected label', () {
      expect(SaveStatus.none.label, 'Ready');
    });

    test('all enum values are accounted for', () {
      expect(SaveStatus.values.length, 5);
    });
  });
}
