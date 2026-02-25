// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_watcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages file watchers for open documents [DD §15]

@ProviderFor(FileWatcherNotifier)
const fileWatcherProvider = FileWatcherNotifierProvider._();

/// Manages file watchers for open documents [DD §15]
final class FileWatcherNotifierProvider
    extends $NotifierProvider<FileWatcherNotifier, FileWatcherService> {
  /// Manages file watchers for open documents [DD §15]
  const FileWatcherNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileWatcherNotifierHash();

  @$internal
  @override
  FileWatcherNotifier create() => FileWatcherNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileWatcherService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileWatcherService>(value),
    );
  }
}

String _$fileWatcherNotifierHash() =>
    r'54dc3e546529d05c8eab31d3b2629ad7defbf633';

/// Manages file watchers for open documents [DD §15]

abstract class _$FileWatcherNotifier extends $Notifier<FileWatcherService> {
  FileWatcherService build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<FileWatcherService, FileWatcherService>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FileWatcherService, FileWatcherService>,
              FileWatcherService,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
