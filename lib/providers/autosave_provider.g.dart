// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'autosave_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages autosave lifecycle — debounced saves on content change

@ProviderFor(Autosave)
const autosaveProvider = AutosaveProvider._();

/// Manages autosave lifecycle — debounced saves on content change
final class AutosaveProvider
    extends $NotifierProvider<Autosave, AutosaveService> {
  /// Manages autosave lifecycle — debounced saves on content change
  const AutosaveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autosaveProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autosaveHash();

  @$internal
  @override
  Autosave create() => Autosave();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutosaveService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutosaveService>(value),
    );
  }
}

String _$autosaveHash() => r'451582b9b22e15195dcd465ebf469e617b4b974b';

/// Manages autosave lifecycle — debounced saves on content change

abstract class _$Autosave extends $Notifier<AutosaveService> {
  AutosaveService build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AutosaveService, AutosaveService>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AutosaveService, AutosaveService>,
              AutosaveService,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
