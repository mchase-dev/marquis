import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hovered_link_provider.g.dart';

/// Holds the URL of the currently hovered link in the viewer, or null.
@Riverpod(keepAlive: true)
class HoveredLinkNotifier extends _$HoveredLinkNotifier {
  @override
  String? build() => null;

  void set(String? url) {
    state = url;
  }
}
