// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cursor_position_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CursorPositionNotifier)
const cursorPositionProvider = CursorPositionNotifierProvider._();

final class CursorPositionNotifierProvider
    extends $NotifierProvider<CursorPositionNotifier, CursorPosition> {
  const CursorPositionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cursorPositionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cursorPositionNotifierHash();

  @$internal
  @override
  CursorPositionNotifier create() => CursorPositionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CursorPosition value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CursorPosition>(value),
    );
  }
}

String _$cursorPositionNotifierHash() =>
    r'32065d6df80e61f3b66dd38cd63392510276dc69';

abstract class _$CursorPositionNotifier extends $Notifier<CursorPosition> {
  CursorPosition build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CursorPosition, CursorPosition>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CursorPosition, CursorPosition>,
              CursorPosition,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
