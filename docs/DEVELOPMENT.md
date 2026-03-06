# Development Guide

## Prerequisites

### Flutter SDK

Install the Flutter SDK (stable channel) for your platform:

- **Linux:** `sudo snap install flutter --classic`
- **Windows:** [Flutter Windows install guide](https://docs.flutter.dev/get-started/install/windows)
- **macOS:** [Flutter macOS install guide](https://docs.flutter.dev/get-started/install/macos)

Verify your setup:

```bash
flutter doctor
```

Marquis requires Dart SDK ^3.10.7 (specified in `pubspec.yaml`).

### Platform Toolchains

**Windows**

- Visual Studio 2022 with "Desktop development with C++" workload
- Developer Mode enabled: `start ms-settings:developers`

**macOS**

- Xcode (latest stable) with command-line tools
- CocoaPods: `sudo gem install cocoapods`

**Linux (including WSL)**

- GCC, Ninja, GTK3 dev headers:

  ```bash
  sudo apt-get install -y ninja-build libgtk-3-dev libblkid-dev liblzma-dev
  ```

---

## Getting Started

### Clone & Build

```bash
git clone https://github.com/mchase-dev/Marquis.git
cd Marquis
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows   # or: -d macos, -d linux
```

### Code Generation

Marquis uses code generation for Riverpod providers (`riverpod_annotation` + `riverpod_generator`). After modifying any provider class annotated with `@riverpod`, regenerate:

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerates on file changes)
dart run build_runner watch --delete-conflicting-outputs
```

---

## Project Structure

```
lib/
├── main.dart                          App entry point (window_manager init, runApp)
├── app.dart                           Root ProviderScope and MaterialApp
├── core/
│   ├── constants.dart                 App-wide constants (colors, sizes, durations)
│   └── file_errors.dart               File operation error types
├── models/
│   ├── command_item.dart              Command palette item model
│   ├── document_state.dart            Per-tab document state (content, path, dirty flag)
│   ├── preferences_state.dart         User preferences model (theme, fonts, autosave)
│   ├── save_status.dart               Save status enum (saved, saving, unsaved, error)
│   └── tab_state.dart                 Tab and TabManagerState models
├── providers/
│   ├── app_links_provider.dart        Single-instance and file-open forwarding
│   ├── autosave_provider.dart         Per-document debounced autosave
│   ├── command_palette_provider.dart   Command palette open/filter state
│   ├── cursor_position_provider.dart   Editor cursor line/column tracking
│   ├── document_provider.dart         Per-tab document state management
│   ├── file_watcher_provider.dart     External file change detection
│   ├── hovered_link_provider.dart     Status bar link preview
│   ├── preferences_provider.dart      Async preferences read/write
│   ├── save_status_provider.dart      Per-document save status
│   ├── show_viewer_images_provider.dart  Image visibility toggle
│   ├── tab_manager_provider.dart      Tab lifecycle (open, close, reorder)
│   ├── theme_provider.dart            Theme derived from preferences
│   └── view_mode_provider.dart        Viewer Only / Split View / Editor Only
├── services/
│   ├── app_links_service.dart         Deep link and file association handling
│   ├── autosave_service.dart          Debounced save timer management
│   ├── file_service.dart              File read/write/pick operations
│   ├── file_watcher_service.dart      OS-native file change watching
│   ├── formatting_service.dart        Markdown formatting insertions
│   ├── markdown_pdf_renderer.dart     Markdown → PDF widget conversion
│   ├── preferences_service.dart       JSON preferences file I/O
│   └── print_service.dart             Print dialog integration
├── theme/
│   ├── app_theme.dart                 Material theme (light/dark, accent color)
│   ├── editor_theme.dart              re_editor syntax highlighting theme
│   └── viewer_theme.dart              markdown_widget rendering theme
└── widgets/
    ├── app_shell.dart                 Main scaffold (menu, tabs, toolbar, split view)
    ├── command_palette/
    │   ├── command_data.dart           Command definitions and Markdown snippets
    │   └── command_palette.dart        Command palette overlay widget
    ├── dialogs/
    │   ├── conflict_dialog.dart        External file change conflict resolution
    │   ├── error_dialog.dart           Error display dialog
    │   ├── file_deleted_dialog.dart    External file deletion handling
    │   ├── rename_dialog.dart          File rename dialog
    │   └── save_dialog.dart            Unsaved changes prompt
    ├── editor/
    │   ├── editor_pane.dart            re_editor wrapper with toolbar
    │   ├── editor_toolbar.dart         Formatting toolbar (bold, italic, etc.)
    │   └── find_replace_bar.dart       Find & Replace bar
    ├── menu_bar/
    │   └── app_menu_bar.dart           Platform-adaptive menu bar
    ├── preferences/
    │   └── preferences_dialog.dart     Preferences UI
    ├── split_view/
    │   └── split_view.dart             Resizable editor/viewer split
    ├── status_bar/
    │   └── status_bar.dart             Bottom status bar (cursor, save status, zoom)
    ├── tab_bar/
    │   ├── app_tab_bar.dart            Tab bar with drag-to-reorder
    │   ├── tab_context_menu.dart        Right-click tab menu
    │   └── tab_item.dart               Individual tab widget
    ├── toolbar/
    │   └── app_toolbar.dart            Main toolbar (view mode, zoom)
    ├── viewer/
    │   ├── viewer_find_bar.dart        Find in viewer bar
    │   └── viewer_pane.dart            markdown_widget rendered view
    └── welcome/
        └── welcome_screen.dart         Welcome screen with recent files
```

---

## Key Architectural Decisions

- **Riverpod with Code Generation:** All providers use `@riverpod` annotations. The generated `.g.dart` files contain the provider boilerplate. Uses `Notifier`/`AsyncNotifier` patterns (Riverpod 3.x), not legacy `StateNotifier`.
- **Manual Immutable Models:** State classes (`DocumentState`, `TabManagerState`, `PreferencesState`) are hand-written with `copyWith()` methods. No Freezed dependency.
- **JSON Preferences:** User settings are stored in a plain JSON file at platform-specific paths — not `shared_preferences`. This makes preferences portable and user-editable.
- **re_editor:** The editor uses a custom rendering engine (not `TextField`-based) with isolate-based syntax highlighting via `re_highlight`. Undo/redo is managed internally by the editor, not by the document model.
- **markdown_widget:** The viewer uses `markdown_widget` for GFM rendering. **Do NOT use `flutter_markdown`** (discontinued April 2025) or **`highlight`** (abandoned).
- **Platform-Adaptive Menu Bar:** Uses `PlatformMenuBar` on macOS and `MenuBar` widget on Windows/Linux.

---

## Common Commands

### Dependencies

```bash
flutter pub get                        # Install dependencies
flutter pub upgrade                    # Upgrade within version constraints
flutter pub upgrade --major-versions   # Upgrade to latest major versions
flutter pub outdated                   # Check for outdated packages
```

### Build & Run

```bash
flutter run -d windows                 # Run on Windows
flutter run -d macos                   # Run on macOS
flutter run -d linux                   # Run on Linux

flutter build windows --release        # Release build for Windows
flutter build macos --release          # Release build for macOS
flutter build linux --release          # Release build for Linux
```

### Analysis & Testing

```bash
flutter analyze                        # Static analysis (lint checks)
flutter test                           # Run all 85 tests
flutter test test/models/              # Run model tests only
flutter test test/path/to/file.dart    # Run specific test file
flutter test --reporter expanded       # Verbose output
```

### Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs   # One-time build
dart run build_runner watch --delete-conflicting-outputs    # Watch mode
```

### Clean Build

When things go wrong, clean and rebuild:

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## Testing

### Test Structure

```
test/
├── widget_test.dart              Smoke test (app loads, shows toolbar)
├── helpers/
│   └── fixtures.dart             Factory functions for test models
├── core/
│   ├── constants_test.dart       App constants tests
│   └── file_errors_test.dart     File error type tests
└── models/
    ├── command_item_test.dart    Command item model tests
    ├── document_state_test.dart  Document state & copyWith tests
    ├── preferences_state_test.dart  Preferences model tests
    ├── save_status_test.dart     Save status enum tests
    └── tab_state_test.dart       Tab state & TabManagerState tests
```

### Test Patterns

- **Fixtures:** `test/helpers/fixtures.dart` provides factory functions for test models
- **ProviderScope:** Widget tests wrap the app in `ProviderScope` for Riverpod
- **Model tests:** Verify constructors, `copyWith()`, equality, and default values
- **No mocking framework:** Tests use plain Dart — no Mockito dependency

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/models/document_state_test.dart

# With verbose output
flutter test --reporter expanded
```

---

## Development Workflow

### After Modifying Providers

```bash
dart run build_runner build --delete-conflicting-outputs
```

### After Changing pubspec.yaml

```bash
flutter pub get
```

### After Upgrading Packages

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Full Rebuild

```bash
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

---

## Troubleshooting

### "SDK version mismatch"

Marquis requires Dart SDK ^3.10.7. Adjust `pubspec.yaml` or upgrade Flutter:

```bash
flutter upgrade
```

### "Missing implementations" on provider classes

Regenerate code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### "Symlink support required" (Windows)

Enable Developer Mode: `start ms-settings:developers`

### window_manager deadlock on Windows

`windowManager.destroy()` can deadlock when `setPreventClose(true)` is set. The app uses `exit(0)` after saving state instead. Platform channel calls inside `onWindowClose` can also deadlock with the Win32 message loop — window state is cached in memory during resize/move and written on close.

### Build artifacts causing issues

```bash
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

---

## Build Output Paths

| Platform | Path |
|----------|------|
| Windows | `build/windows/x64/runner/Release/` |
| macOS | `build/macos/Build/Products/Release/Marquis.app` |
| Linux | `build/linux/x64/release/bundle/` |
