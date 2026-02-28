import 'package:flutter_test/flutter_test.dart';
import '../helpers/fixtures.dart';

void main() {
  group('TabManagerState', () {
    group('hasTabs', () {
      test('false when tabIds is empty', () {
        final state = makeTabManagerState();
        expect(state.hasTabs, isFalse);
      });

      test('true when tabIds is non-empty', () {
        final state = makeTabManagerState(
          tabIds: ['tab-1'],
          activeTabIndex: 0,
        );
        expect(state.hasTabs, isTrue);
      });
    });

    group('activeTabId', () {
      test('returns correct ID for valid index', () {
        final state = makeTabManagerState(
          tabIds: ['tab-1', 'tab-2', 'tab-3'],
          activeTabIndex: 1,
        );
        expect(state.activeTabId, 'tab-2');
      });

      test('returns null when activeTabIndex is -1', () {
        final state = makeTabManagerState(
          tabIds: ['tab-1'],
          activeTabIndex: -1,
        );
        expect(state.activeTabId, isNull);
      });

      test('returns null when activeTabIndex is out of range', () {
        final state = makeTabManagerState(
          tabIds: ['tab-1'],
          activeTabIndex: 5,
        );
        expect(state.activeTabId, isNull);
      });

      test('returns null when tabIds is empty', () {
        final state = makeTabManagerState();
        expect(state.activeTabId, isNull);
      });
    });

    group('tabCount', () {
      test('returns 0 for empty state', () {
        final state = makeTabManagerState();
        expect(state.tabCount, 0);
      });

      test('returns length of tabIds', () {
        final state = makeTabManagerState(
          tabIds: ['a', 'b', 'c'],
        );
        expect(state.tabCount, 3);
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final state = makeTabManagerState(
          tabIds: ['tab-1'],
          activeTabIndex: 0,
          revision: 5,
        );
        final copy = state.copyWith(activeTabIndex: 0);
        expect(copy.tabIds, ['tab-1']);
        expect(copy.revision, 5);
      });

      test('overrides specified fields', () {
        final state = makeTabManagerState(
          tabIds: ['tab-1'],
          activeTabIndex: 0,
        );
        final copy = state.copyWith(
          tabIds: ['tab-1', 'tab-2'],
          activeTabIndex: 1,
        );
        expect(copy.tabIds, ['tab-1', 'tab-2']);
        expect(copy.activeTabIndex, 1);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final a = makeTabManagerState(
          tabIds: ['tab-1', 'tab-2'],
          activeTabIndex: 0,
          revision: 3,
        );
        final b = makeTabManagerState(
          tabIds: ['tab-1', 'tab-2'],
          activeTabIndex: 0,
          revision: 3,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when tabIds differ', () {
        final a = makeTabManagerState(tabIds: ['tab-1']);
        final b = makeTabManagerState(tabIds: ['tab-2']);
        expect(a, isNot(equals(b)));
      });

      test('not equal when revision differs', () {
        final a = makeTabManagerState(revision: 1);
        final b = makeTabManagerState(revision: 2);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
