/// Represents the state of a single open document [DD §7]
class DocumentState {
  final String id;
  final String content;
  final String? filePath;
  final String? lastSavedContent;
  final DateTime? lastModified;
  final bool isEditMode;
  final bool isExternallyModified;
  final String encoding;
  final bool isReadOnly;
  final String? helpTitle;

  const DocumentState({
    required this.id,
    this.content = '',
    this.filePath,
    this.lastSavedContent,
    this.lastModified,
    this.isEditMode = false,
    this.isExternallyModified = false,
    this.encoding = 'utf-8',
    this.isReadOnly = false,
    this.helpTitle,
  });

  /// Whether the document has unsaved changes [DD §6 — Dirty state]
  bool get isDirty => content != (lastSavedContent ?? '');

  /// Whether this is an untitled/new file [DD §6 — New/Untitled state]
  bool get isUntitled => filePath == null;

  /// Whether this is a help document [DD §12 — Help Content]
  bool get isHelpDocument => helpTitle != null;

  /// Display name for tabs and title bar [DD §5, §6]
  String get displayName {
    if (helpTitle != null) return helpTitle!;
    if (filePath != null) {
      return filePath!.split(RegExp(r'[/\\]')).last;
    }
    return 'Untitled';
  }

  DocumentState copyWith({
    String? id,
    String? content,
    String? filePath,
    String? lastSavedContent,
    DateTime? lastModified,
    bool? isEditMode,
    bool? isExternallyModified,
    String? encoding,
    bool? isReadOnly,
    String? helpTitle,
    bool clearFilePath = false,
    bool clearLastSavedContent = false,
    bool clearLastModified = false,
  }) {
    return DocumentState(
      id: id ?? this.id,
      content: content ?? this.content,
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      lastSavedContent: clearLastSavedContent
          ? null
          : (lastSavedContent ?? this.lastSavedContent),
      lastModified:
          clearLastModified ? null : (lastModified ?? this.lastModified),
      isEditMode: isEditMode ?? this.isEditMode,
      isExternallyModified:
          isExternallyModified ?? this.isExternallyModified,
      encoding: encoding ?? this.encoding,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      helpTitle: helpTitle ?? this.helpTitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentState &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          filePath == other.filePath &&
          lastSavedContent == other.lastSavedContent &&
          lastModified == other.lastModified &&
          isEditMode == other.isEditMode &&
          isExternallyModified == other.isExternallyModified &&
          encoding == other.encoding &&
          isReadOnly == other.isReadOnly &&
          helpTitle == other.helpTitle;

  @override
  int get hashCode => Object.hash(
        id,
        content,
        filePath,
        lastSavedContent,
        lastModified,
        isEditMode,
        isExternallyModified,
        encoding,
        isReadOnly,
        helpTitle,
      );
}
