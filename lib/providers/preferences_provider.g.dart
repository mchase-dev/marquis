// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides reactive access to user preferences

@ProviderFor(Preferences)
const preferencesProvider = PreferencesProvider._();

/// Provides reactive access to user preferences
final class PreferencesProvider
    extends $AsyncNotifierProvider<Preferences, PreferencesState> {
  /// Provides reactive access to user preferences
  const PreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferencesHash();

  @$internal
  @override
  Preferences create() => Preferences();
}

String _$preferencesHash() => r'0846e27c894867826d3b2e8f82c61dba85d53d1a';

/// Provides reactive access to user preferences

abstract class _$Preferences extends $AsyncNotifier<PreferencesState> {
  FutureOr<PreferencesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<PreferencesState>, PreferencesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PreferencesState>, PreferencesState>,
              AsyncValue<PreferencesState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
