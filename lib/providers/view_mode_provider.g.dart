// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'view_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks the current view mode [DD §10 — Toggling Edit Mode]

@ProviderFor(ViewModeNotifier)
const viewModeProvider = ViewModeNotifierProvider._();

/// Tracks the current view mode [DD §10 — Toggling Edit Mode]
final class ViewModeNotifierProvider
    extends $NotifierProvider<ViewModeNotifier, ViewMode> {
  /// Tracks the current view mode [DD §10 — Toggling Edit Mode]
  const ViewModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewModeNotifierHash();

  @$internal
  @override
  ViewModeNotifier create() => ViewModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ViewMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ViewMode>(value),
    );
  }
}

String _$viewModeNotifierHash() => r'dbc98a2c4bf9881985c5cd7cf491673195d2fbe9';

/// Tracks the current view mode [DD §10 — Toggling Edit Mode]

abstract class _$ViewModeNotifier extends $Notifier<ViewMode> {
  ViewMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ViewMode, ViewMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ViewMode, ViewMode>,
              ViewMode,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
