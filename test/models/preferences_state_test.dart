import 'package:flutter_test/flutter_test.dart';
import 'package:marquis/models/preferences_state.dart';
import '../helpers/fixtures.dart';

void main() {
  group('PreferencesState', () {
    group('toJson / fromJson round-trip', () {
      test('full state survives serialization', () {
        final original = makePreferencesState(
          appearance: const AppearancePrefs(
            theme: ThemeModePref.dark,
            accentColor: '#FF0000',
            viewerFontSize: 18,
            editorFontSize: 16,
            editorFontFamily: 'Fira Code',
            zoomLevel: 125,
          ),
          editor: const EditorPrefs(
            wordWrap: false,
            showLineNumbers: false,
            tabSize: 2,
            highlightActiveLine: false,
            autoIndent: false,
          ),
          autosave: const AutosavePrefs(
            enabled: false,
            delaySec: 10,
          ),
          general: const GeneralPrefs(
            recentFiles: ['/tmp/a.md', '/tmp/b.md'],
            maxRecentFiles: 5,
          ),
          window: const WindowPrefs(
            width: 1400,
            height: 900,
            x: 100,
            y: 200,
            isMaximized: true,
          ),
        );

        final json = original.toJson();
        final restored = PreferencesState.fromJson(json);

        // Appearance
        expect(restored.appearance.theme, ThemeModePref.dark);
        expect(restored.appearance.accentColor, '#FF0000');
        expect(restored.appearance.viewerFontSize, 18);
        expect(restored.appearance.editorFontSize, 16);
        expect(restored.appearance.editorFontFamily, 'Fira Code');
        expect(restored.appearance.zoomLevel, 125);

        // Editor
        expect(restored.editor.wordWrap, isFalse);
        expect(restored.editor.showLineNumbers, isFalse);
        expect(restored.editor.tabSize, 2);
        expect(restored.editor.highlightActiveLine, isFalse);
        expect(restored.editor.autoIndent, isFalse);

        // Autosave
        expect(restored.autosave.enabled, isFalse);
        expect(restored.autosave.delaySec, 10);

        // General
        expect(restored.general.recentFiles, ['/tmp/a.md', '/tmp/b.md']);
        expect(restored.general.maxRecentFiles, 5);

        // Window
        expect(restored.window.width, 1400);
        expect(restored.window.height, 900);
        expect(restored.window.x, 100);
        expect(restored.window.y, 200);
        expect(restored.window.isMaximized, isTrue);
      });

      test('fromJson with empty map returns all defaults', () {
        final state = PreferencesState.fromJson({});

        expect(state.appearance.theme, ThemeModePref.system);
        expect(state.appearance.accentColor, '#6C63FF');
        expect(state.appearance.viewerFontSize, 16);
        expect(state.appearance.editorFontSize, 14);
        expect(state.editor.wordWrap, isTrue);
        expect(state.editor.showLineNumbers, isTrue);
        expect(state.editor.tabSize, 4);
        expect(state.autosave.enabled, isTrue);
        expect(state.autosave.delaySec, 3);
        expect(state.general.recentFiles, isEmpty);
        expect(state.general.maxRecentFiles, 10);
        expect(state.window.width, 1200);
        expect(state.window.height, 800);
        expect(state.window.isMaximized, isFalse);
      });

      test('fromJson with partial data fills in defaults', () {
        final state = PreferencesState.fromJson({
          'appearance': {'theme': 'dark'},
          'editor': {'tabSize': 2},
        });

        expect(state.appearance.theme, ThemeModePref.dark);
        expect(state.appearance.accentColor, '#6C63FF'); // default
        expect(state.editor.tabSize, 2);
        expect(state.editor.wordWrap, isTrue); // default
        expect(state.autosave.enabled, isTrue); // default section
      });

      test('fromJson with invalid theme string falls back to system', () {
        final state = PreferencesState.fromJson({
          'appearance': {'theme': 'nope'},
        });
        expect(state.appearance.theme, ThemeModePref.system);
      });
    });

    group('AppearancePrefs', () {
      test('round-trips through JSON', () {
        const original = AppearancePrefs(
          theme: ThemeModePref.light,
          accentColor: '#00FF00',
          viewerFontSize: 20,
        );
        final restored = AppearancePrefs.fromJson(original.toJson());
        expect(restored.theme, ThemeModePref.light);
        expect(restored.accentColor, '#00FF00');
        expect(restored.viewerFontSize, 20);
      });

      test('copyWith overrides specified fields', () {
        const prefs = AppearancePrefs();
        final copy = prefs.copyWith(theme: ThemeModePref.dark, zoomLevel: 150);
        expect(copy.theme, ThemeModePref.dark);
        expect(copy.zoomLevel, 150);
        expect(copy.accentColor, '#6C63FF'); // unchanged
      });
    });

    group('EditorPrefs', () {
      test('round-trips through JSON', () {
        const original = EditorPrefs(
          wordWrap: false,
          tabSize: 8,
          autoIndent: false,
        );
        final restored = EditorPrefs.fromJson(original.toJson());
        expect(restored.wordWrap, isFalse);
        expect(restored.tabSize, 8);
        expect(restored.autoIndent, isFalse);
      });

      test('copyWith overrides specified fields', () {
        const prefs = EditorPrefs();
        final copy = prefs.copyWith(wordWrap: false);
        expect(copy.wordWrap, isFalse);
        expect(copy.showLineNumbers, isTrue); // unchanged
      });
    });

    group('AutosavePrefs', () {
      test('round-trips through JSON', () {
        const original = AutosavePrefs(enabled: false, delaySec: 5);
        final restored = AutosavePrefs.fromJson(original.toJson());
        expect(restored.enabled, isFalse);
        expect(restored.delaySec, 5);
      });

      test('copyWith overrides specified fields', () {
        const prefs = AutosavePrefs();
        final copy = prefs.copyWith(delaySec: 10);
        expect(copy.delaySec, 10);
        expect(copy.enabled, isTrue); // unchanged
      });
    });

    group('GeneralPrefs', () {
      test('round-trips through JSON', () {
        const original = GeneralPrefs(
          recentFiles: ['/a.md', '/b.md'],
          maxRecentFiles: 20,
        );
        final restored = GeneralPrefs.fromJson(original.toJson());
        expect(restored.recentFiles, ['/a.md', '/b.md']);
        expect(restored.maxRecentFiles, 20);
      });

      test('copyWith overrides specified fields', () {
        const prefs = GeneralPrefs();
        final copy = prefs.copyWith(maxRecentFiles: 5);
        expect(copy.maxRecentFiles, 5);
        expect(copy.recentFiles, isEmpty); // unchanged
      });
    });

    group('WindowPrefs', () {
      test('round-trips through JSON', () {
        const original = WindowPrefs(
          width: 1600,
          height: 1000,
          x: 50,
          y: 75,
          isMaximized: true,
        );
        final restored = WindowPrefs.fromJson(original.toJson());
        expect(restored.width, 1600);
        expect(restored.height, 1000);
        expect(restored.x, 50);
        expect(restored.y, 75);
        expect(restored.isMaximized, isTrue);
      });

      test('fromJson with null x/y', () {
        final restored = WindowPrefs.fromJson({
          'width': 1200,
          'height': 800,
          'x': null,
          'y': null,
          'isMaximized': false,
        });
        expect(restored.x, isNull);
        expect(restored.y, isNull);
      });

      test('copyWith with clearX/clearY', () {
        const prefs = WindowPrefs(x: 100, y: 200);
        final copy = prefs.copyWith(clearX: true, clearY: true);
        expect(copy.x, isNull);
        expect(copy.y, isNull);
        expect(copy.width, prefs.width); // unchanged
      });
    });

    group('copyWith', () {
      test('preserves unchanged sub-models', () {
        final state = makePreferencesState(
          appearance: const AppearancePrefs(theme: ThemeModePref.dark),
        );
        final copy = state.copyWith(
          editor: const EditorPrefs(tabSize: 2),
        );
        expect(copy.appearance.theme, ThemeModePref.dark);
        expect(copy.editor.tabSize, 2);
      });
    });
  });
}
