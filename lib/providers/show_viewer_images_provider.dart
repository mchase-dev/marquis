import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:marquis/providers/view_mode_provider.dart';

part 'show_viewer_images_provider.g.dart';

/// Controls image visibility in the viewer pane.
///
/// Auto-shows images in viewer-only mode, auto-hides in split/editor-only
/// to improve scroll sync (images take variable space vs a single `![]()`
/// line in the editor). The user can manually [toggle] via the toolbar;
/// the override resets on the next view-mode change because [build] re-runs.
@riverpod
class ShowViewerImages extends _$ShowViewerImages {
  @override
  bool build() {
    final viewMode = ref.watch(viewModeProvider);
    return viewMode == ViewMode.viewerOnly;
  }

  void toggle() => state = !state;
}
