import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:marquis/models/save_status.dart';
import 'package:marquis/providers/document_provider.dart';
import 'package:marquis/providers/preferences_provider.dart';

part 'save_status_provider.g.dart';

/// Derived provider computing the current save status for the status bar
@riverpod
SaveStatus saveStatus(Ref ref) {
  final doc = ref.watch(activeDocumentProvider);
  if (doc == null) return SaveStatus.none;

  // Help/read-only docs don't have a save status
  if (doc.isReadOnly) return SaveStatus.none;

  final prefs = ref.watch(preferencesProvider).value;
  final autosaveEnabled = prefs?.autosave.enabled ?? true;

  if (!doc.isDirty) return SaveStatus.saved;

  // Dirty document
  if (!autosaveEnabled) return SaveStatus.disabled;
  return SaveStatus.unsaved;
}
