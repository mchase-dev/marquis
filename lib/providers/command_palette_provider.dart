import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'command_palette_provider.g.dart';

/// State for the command palette
class CommandPaletteState {
  final bool isOpen;
  final String filterText;

  const CommandPaletteState({
    this.isOpen = false,
    this.filterText = '',
  });

  CommandPaletteState copyWith({
    bool? isOpen,
    String? filterText,
  }) {
    return CommandPaletteState(
      isOpen: isOpen ?? this.isOpen,
      filterText: filterText ?? this.filterText,
    );
  }
}

/// Manages command palette open/close and filter state
@Riverpod(keepAlive: true)
class CommandPaletteNotifier extends _$CommandPaletteNotifier {
  @override
  CommandPaletteState build() => const CommandPaletteState();

  void open() {
    state = state.copyWith(isOpen: true, filterText: '');
  }

  void close() {
    state = state.copyWith(isOpen: false, filterText: '');
  }

  void toggle() {
    if (state.isOpen) {
      close();
    } else {
      open();
    }
  }

  void setFilter(String text) {
    state = state.copyWith(filterText: text);
  }
}
