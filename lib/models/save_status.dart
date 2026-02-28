/// Save status for status bar display
enum SaveStatus {
  saved('Saved'),
  saving('Saving...'),
  unsaved('Unsaved changes'),
  disabled('Auto-save: off'),
  none('Ready');

  final String label;
  const SaveStatus(this.label);
}
