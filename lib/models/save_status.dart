/// Save status for status bar display [DD §5 — Status Bar]
enum SaveStatus {
  saved('Saved'),
  saving('Saving...'),
  unsaved('Unsaved changes'),
  disabled('Auto-save: off'),
  none('Ready');

  final String label;
  const SaveStatus(this.label);
}
