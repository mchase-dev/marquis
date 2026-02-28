// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_palette_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages command palette open/close and filter state

@ProviderFor(CommandPaletteNotifier)
const commandPaletteProvider = CommandPaletteNotifierProvider._();

/// Manages command palette open/close and filter state
final class CommandPaletteNotifierProvider
    extends $NotifierProvider<CommandPaletteNotifier, CommandPaletteState> {
  /// Manages command palette open/close and filter state
  const CommandPaletteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commandPaletteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commandPaletteNotifierHash();

  @$internal
  @override
  CommandPaletteNotifier create() => CommandPaletteNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommandPaletteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommandPaletteState>(value),
    );
  }
}

String _$commandPaletteNotifierHash() =>
    r'dfdfee1489074b1fe03a51f744acc88ebe49eeac';

/// Manages command palette open/close and filter state

abstract class _$CommandPaletteNotifier extends $Notifier<CommandPaletteState> {
  CommandPaletteState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CommandPaletteState, CommandPaletteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CommandPaletteState, CommandPaletteState>,
              CommandPaletteState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
