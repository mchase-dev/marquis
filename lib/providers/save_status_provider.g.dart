// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Derived provider computing the current save status for the status bar

@ProviderFor(saveStatus)
const saveStatusProvider = SaveStatusProvider._();

/// Derived provider computing the current save status for the status bar

final class SaveStatusProvider
    extends $FunctionalProvider<SaveStatus, SaveStatus, SaveStatus>
    with $Provider<SaveStatus> {
  /// Derived provider computing the current save status for the status bar
  const SaveStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveStatusHash();

  @$internal
  @override
  $ProviderElement<SaveStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SaveStatus create(Ref ref) {
    return saveStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveStatus>(value),
    );
  }
}

String _$saveStatusHash() => r'685c442c24ee6b253141db741fd77113e4fc2ccd';
