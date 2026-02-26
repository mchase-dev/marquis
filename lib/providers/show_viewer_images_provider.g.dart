// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_viewer_images_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls image visibility in the viewer pane.
///
/// Auto-shows images in viewer-only mode, auto-hides in split/editor-only
/// to improve scroll sync (images take variable space vs a single `![]()`
/// line in the editor). The user can manually [toggle] via the toolbar;
/// the override resets on the next view-mode change because [build] re-runs.

@ProviderFor(ShowViewerImages)
const showViewerImagesProvider = ShowViewerImagesProvider._();

/// Controls image visibility in the viewer pane.
///
/// Auto-shows images in viewer-only mode, auto-hides in split/editor-only
/// to improve scroll sync (images take variable space vs a single `![]()`
/// line in the editor). The user can manually [toggle] via the toolbar;
/// the override resets on the next view-mode change because [build] re-runs.
final class ShowViewerImagesProvider
    extends $NotifierProvider<ShowViewerImages, bool> {
  /// Controls image visibility in the viewer pane.
  ///
  /// Auto-shows images in viewer-only mode, auto-hides in split/editor-only
  /// to improve scroll sync (images take variable space vs a single `![]()`
  /// line in the editor). The user can manually [toggle] via the toolbar;
  /// the override resets on the next view-mode change because [build] re-runs.
  const ShowViewerImagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showViewerImagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showViewerImagesHash();

  @$internal
  @override
  ShowViewerImages create() => ShowViewerImages();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showViewerImagesHash() => r'c6f651cdacb6365e07ac55a1f7a31c20c56f5832';

/// Controls image visibility in the viewer pane.
///
/// Auto-shows images in viewer-only mode, auto-hides in split/editor-only
/// to improve scroll sync (images take variable space vs a single `![]()`
/// line in the editor). The user can manually [toggle] via the toolbar;
/// the override resets on the next view-mode change because [build] re-runs.

abstract class _$ShowViewerImages extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
