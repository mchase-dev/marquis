import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:marquis/models/document_state.dart';
import 'package:marquis/providers/tab_manager_provider.dart';

part 'document_provider.g.dart';

/// Per-tab document state, keyed by tab ID [DD §4 — documentProvider(tabId)]
@riverpod
DocumentState? document(Ref ref, String tabId) {
  // Watch the tab manager state to react to changes
  ref.watch(tabManagerProvider);
  return ref.read(tabManagerProvider.notifier).getDocument(tabId);
}

/// The currently active document [DD §4 — activeDocumentProvider]
@riverpod
DocumentState? activeDocument(Ref ref) {
  final tabState = ref.watch(tabManagerProvider);
  final activeId = tabState.activeTabId;
  if (activeId == null) return null;
  return ref.read(tabManagerProvider.notifier).getDocument(activeId);
}
