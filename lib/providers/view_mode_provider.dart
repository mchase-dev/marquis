import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'view_mode_provider.g.dart';

/// Layout modes for the content area [DD §10]
enum ViewMode { viewerOnly, split, editorOnly }

/// Tracks the current view mode [DD §10 — Toggling Edit Mode]
@Riverpod(keepAlive: true)
class ViewModeNotifier extends _$ViewModeNotifier {
  @override
  ViewMode build() => ViewMode.viewerOnly;

  void setMode(ViewMode mode) => state = mode;

  /// Ctrl+E: toggle Viewer Only <-> Split View
  void toggleEdit() {
    state = state == ViewMode.viewerOnly ? ViewMode.split : ViewMode.viewerOnly;
  }

  /// Ctrl+Shift+E: toggle Split View <-> Editor Only
  void toggleEditorOnly() {
    state = state == ViewMode.editorOnly ? ViewMode.split : ViewMode.editorOnly;
  }
}
