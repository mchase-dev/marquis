// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_links_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the app_links service lifecycle

@ProviderFor(AppLinksNotifier)
const appLinksProvider = AppLinksNotifierProvider._();

/// Manages the app_links service lifecycle
final class AppLinksNotifierProvider
    extends $NotifierProvider<AppLinksNotifier, void> {
  /// Manages the app_links service lifecycle
  const AppLinksNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLinksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLinksNotifierHash();

  @$internal
  @override
  AppLinksNotifier create() => AppLinksNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$appLinksNotifierHash() => r'1dffe1ebfaa327fe4cf79179469cfef37020aa75';

/// Manages the app_links service lifecycle

abstract class _$AppLinksNotifier extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
