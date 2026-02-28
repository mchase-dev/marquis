import 'package:flutter_test/flutter_test.dart';
import 'package:marquis/models/command_item.dart';
import '../helpers/fixtures.dart';

void main() {
  group('CommandItem', () {
    group('isSnippet', () {
      test('true when snippet is set', () {
        final item = makeCommandItem(snippet: '**bold**');
        expect(item.isSnippet, isTrue);
      });

      test('false when snippet is null', () {
        final item = makeCommandItem();
        expect(item.isSnippet, isFalse);
      });
    });

    group('isAppCommand', () {
      test('true when action is set', () {
        final item = makeCommandItem(action: () {});
        expect(item.isAppCommand, isTrue);
      });

      test('false when action is null', () {
        final item = makeCommandItem();
        expect(item.isAppCommand, isFalse);
      });
    });

    test('category defaults to snippet', () {
      final item = makeCommandItem();
      expect(item.category, CommandCategory.snippet);
    });

    test('stores name and description', () {
      final item = makeCommandItem(
        name: 'Bold',
        description: 'Insert bold text',
      );
      expect(item.name, 'Bold');
      expect(item.description, 'Insert bold text');
    });
  });
}
