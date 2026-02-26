// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hovered_link_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the URL of the currently hovered link in the viewer, or null.

@ProviderFor(HoveredLinkNotifier)
const hoveredLinkProvider = HoveredLinkNotifierProvider._();

/// Holds the URL of the currently hovered link in the viewer, or null.
final class HoveredLinkNotifierProvider
    extends $NotifierProvider<HoveredLinkNotifier, String?> {
  /// Holds the URL of the currently hovered link in the viewer, or null.
  const HoveredLinkNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hoveredLinkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hoveredLinkNotifierHash();

  @$internal
  @override
  HoveredLinkNotifier create() => HoveredLinkNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$hoveredLinkNotifierHash() =>
    r'60cf642326428ccf83018ba65b9a100e949d86b1';

/// Holds the URL of the currently hovered link in the viewer, or null.

abstract class _$HoveredLinkNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
