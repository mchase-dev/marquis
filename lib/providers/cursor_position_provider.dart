import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cursor_position_provider.g.dart';

/// Cursor position state for status bar [DD §5 — Status Bar]
typedef CursorPosition = ({int line, int column});

@Riverpod(keepAlive: true)
class CursorPositionNotifier extends _$CursorPositionNotifier {
  @override
  CursorPosition build() => (line: 1, column: 1);

  void update(int line, int column) {
    state = (line: line, column: column);
  }
}
