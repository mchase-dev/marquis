// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-tab document state, keyed by tab ID [DD §4 — documentProvider(tabId)]

@ProviderFor(document)
const documentProvider = DocumentFamily._();

/// Per-tab document state, keyed by tab ID [DD §4 — documentProvider(tabId)]

final class DocumentProvider
    extends $FunctionalProvider<DocumentState?, DocumentState?, DocumentState?>
    with $Provider<DocumentState?> {
  /// Per-tab document state, keyed by tab ID [DD §4 — documentProvider(tabId)]
  const DocumentProvider._({
    required DocumentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentHash();

  @override
  String toString() {
    return r'documentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<DocumentState?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DocumentState? create(Ref ref) {
    final argument = this.argument as String;
    return document(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentState?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentHash() => r'ffe5860c7757d89aa5303d938213e1acdbadb57a';

/// Per-tab document state, keyed by tab ID [DD §4 — documentProvider(tabId)]

final class DocumentFamily extends $Family
    with $FunctionalFamilyOverride<DocumentState?, String> {
  const DocumentFamily._()
    : super(
        retry: null,
        name: r'documentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-tab document state, keyed by tab ID [DD §4 — documentProvider(tabId)]

  DocumentProvider call(String tabId) =>
      DocumentProvider._(argument: tabId, from: this);

  @override
  String toString() => r'documentProvider';
}

/// The currently active document [DD §4 — activeDocumentProvider]

@ProviderFor(activeDocument)
const activeDocumentProvider = ActiveDocumentProvider._();

/// The currently active document [DD §4 — activeDocumentProvider]

final class ActiveDocumentProvider
    extends $FunctionalProvider<DocumentState?, DocumentState?, DocumentState?>
    with $Provider<DocumentState?> {
  /// The currently active document [DD §4 — activeDocumentProvider]
  const ActiveDocumentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeDocumentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeDocumentHash();

  @$internal
  @override
  $ProviderElement<DocumentState?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DocumentState? create(Ref ref) {
    return activeDocument(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentState?>(value),
    );
  }
}

String _$activeDocumentHash() => r'cac62f8d2497a45b3a376ad883b05aedf48fb1c2';
