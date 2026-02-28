import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:marquis/services/app_links_service.dart';

part 'app_links_provider.g.dart';

/// Manages the app_links service lifecycle
@Riverpod(keepAlive: true)
class AppLinksNotifier extends _$AppLinksNotifier {
  AppLinksService? _service;

  @override
  void build() {
    ref.onDispose(() {
      _service?.dispose();
    });
  }

  /// Initialize with command-line args. Called once from AppShell.
  void init(List<String> args) {
    if (_service != null) return; // Already initialized
    _service = AppLinksService(ref);
    _service!.init(args);
  }
}
