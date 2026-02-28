import 'package:marquis/models/command_item.dart';
import 'package:marquis/models/document_state.dart';
import 'package:marquis/models/preferences_state.dart';
import 'package:marquis/models/tab_state.dart';

/// Creates a [DocumentState] with sensible defaults for testing.
DocumentState makeDocumentState({
  String id = 'doc-1',
  String content = '',
  String? filePath,
  String? lastSavedContent,
  DateTime? lastModified,
  bool isEditMode = false,
  bool isExternallyModified = false,
  String encoding = 'utf-8',
  bool isReadOnly = false,
  String? helpTitle,
}) {
  return DocumentState(
    id: id,
    content: content,
    filePath: filePath,
    lastSavedContent: lastSavedContent,
    lastModified: lastModified,
    isEditMode: isEditMode,
    isExternallyModified: isExternallyModified,
    encoding: encoding,
    isReadOnly: isReadOnly,
    helpTitle: helpTitle,
  );
}

/// Creates a [TabManagerState] with sensible defaults for testing.
TabManagerState makeTabManagerState({
  List<String> tabIds = const [],
  int activeTabIndex = -1,
  int revision = 0,
}) {
  return TabManagerState(
    tabIds: tabIds,
    activeTabIndex: activeTabIndex,
    revision: revision,
  );
}

/// Creates a [PreferencesState] with all defaults for testing.
PreferencesState makePreferencesState({
  AppearancePrefs appearance = const AppearancePrefs(),
  EditorPrefs editor = const EditorPrefs(),
  AutosavePrefs autosave = const AutosavePrefs(),
  GeneralPrefs general = const GeneralPrefs(),
  WindowPrefs window = const WindowPrefs(),
}) {
  return PreferencesState(
    appearance: appearance,
    editor: editor,
    autosave: autosave,
    general: general,
    window: window,
  );
}

/// Creates a [CommandItem] with sensible defaults for testing.
CommandItem makeCommandItem({
  String name = 'Test Command',
  String? description,
  String? snippet,
  String? shortcut,
  CommandCategory category = CommandCategory.snippet,
  void Function()? action,
}) {
  return CommandItem(
    name: name,
    description: description,
    snippet: snippet,
    shortcut: shortcut,
    category: category,
    action: action,
  );
}
