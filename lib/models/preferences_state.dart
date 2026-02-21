import 'package:marquis/core/constants.dart';

/// User preferences state [DD §17, Appendix B]
class PreferencesState {
  final AppearancePrefs appearance;
  final EditorPrefs editor;
  final AutosavePrefs autosave;
  final GeneralPrefs general;
  final WindowPrefs window;

  const PreferencesState({
    this.appearance = const AppearancePrefs(),
    this.editor = const EditorPrefs(),
    this.autosave = const AutosavePrefs(),
    this.general = const GeneralPrefs(),
    this.window = const WindowPrefs(),
  });

  PreferencesState copyWith({
    AppearancePrefs? appearance,
    EditorPrefs? editor,
    AutosavePrefs? autosave,
    GeneralPrefs? general,
    WindowPrefs? window,
  }) {
    return PreferencesState(
      appearance: appearance ?? this.appearance,
      editor: editor ?? this.editor,
      autosave: autosave ?? this.autosave,
      general: general ?? this.general,
      window: window ?? this.window,
    );
  }

  Map<String, dynamic> toJson() => {
        'appearance': appearance.toJson(),
        'editor': editor.toJson(),
        'autosave': autosave.toJson(),
        'general': general.toJson(),
        'window': window.toJson(),
      };

  factory PreferencesState.fromJson(Map<String, dynamic> json) {
    return PreferencesState(
      appearance: json['appearance'] != null
          ? AppearancePrefs.fromJson(json['appearance'] as Map<String, dynamic>)
          : const AppearancePrefs(),
      editor: json['editor'] != null
          ? EditorPrefs.fromJson(json['editor'] as Map<String, dynamic>)
          : const EditorPrefs(),
      autosave: json['autosave'] != null
          ? AutosavePrefs.fromJson(json['autosave'] as Map<String, dynamic>)
          : const AutosavePrefs(),
      general: json['general'] != null
          ? GeneralPrefs.fromJson(json['general'] as Map<String, dynamic>)
          : const GeneralPrefs(),
      window: json['window'] != null
          ? WindowPrefs.fromJson(json['window'] as Map<String, dynamic>)
          : const WindowPrefs(),
    );
  }
}

/// Theme mode setting [DD §17 — Appearance]
enum ThemeModePref { light, dark, system }

/// Appearance preferences [DD §17 — Appearance section]
class AppearancePrefs {
  final ThemeModePref theme;
  final String accentColor;
  final int viewerFontSize;
  final int editorFontSize;
  final String editorFontFamily;
  final int zoomLevel;

  const AppearancePrefs({
    this.theme = ThemeModePref.system,
    this.accentColor = '#6C63FF',
    this.viewerFontSize = 16,
    this.editorFontSize = 14,
    this.editorFontFamily = 'JetBrains Mono',
    this.zoomLevel = 100,
  });

  AppearancePrefs copyWith({
    ThemeModePref? theme,
    String? accentColor,
    int? viewerFontSize,
    int? editorFontSize,
    String? editorFontFamily,
    int? zoomLevel,
  }) {
    return AppearancePrefs(
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      viewerFontSize: viewerFontSize ?? this.viewerFontSize,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      editorFontFamily: editorFontFamily ?? this.editorFontFamily,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'accentColor': accentColor,
        'viewerFontSize': viewerFontSize,
        'editorFontSize': editorFontSize,
        'editorFontFamily': editorFontFamily,
        'zoomLevel': zoomLevel,
      };

  factory AppearancePrefs.fromJson(Map<String, dynamic> json) {
    return AppearancePrefs(
      theme: ThemeModePref.values.firstWhere(
        (e) => e.name == json['theme'],
        orElse: () => ThemeModePref.system,
      ),
      accentColor:
          json['accentColor'] as String? ?? '#6C63FF',
      viewerFontSize: (json['viewerFontSize'] as num?)?.toInt() ?? 16,
      editorFontSize: (json['editorFontSize'] as num?)?.toInt() ?? 14,
      editorFontFamily: json['editorFontFamily'] as String? ??
          AppConstants.defaultEditorFontFamily,
      zoomLevel: (json['zoomLevel'] as num?)?.toInt() ?? 100,
    );
  }
}

/// Editor preferences [DD §17 — Editor section]
class EditorPrefs {
  final bool wordWrap;
  final bool showLineNumbers;
  final int tabSize;
  final bool highlightActiveLine;
  final bool autoIndent;

  const EditorPrefs({
    this.wordWrap = true,
    this.showLineNumbers = true,
    this.tabSize = 4,
    this.highlightActiveLine = true,
    this.autoIndent = true,
  });

  EditorPrefs copyWith({
    bool? wordWrap,
    bool? showLineNumbers,
    int? tabSize,
    bool? highlightActiveLine,
    bool? autoIndent,
  }) {
    return EditorPrefs(
      wordWrap: wordWrap ?? this.wordWrap,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      tabSize: tabSize ?? this.tabSize,
      highlightActiveLine: highlightActiveLine ?? this.highlightActiveLine,
      autoIndent: autoIndent ?? this.autoIndent,
    );
  }

  Map<String, dynamic> toJson() => {
        'wordWrap': wordWrap,
        'showLineNumbers': showLineNumbers,
        'tabSize': tabSize,
        'highlightActiveLine': highlightActiveLine,
        'autoIndent': autoIndent,
      };

  factory EditorPrefs.fromJson(Map<String, dynamic> json) {
    return EditorPrefs(
      wordWrap: json['wordWrap'] as bool? ?? true,
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
      tabSize: (json['tabSize'] as num?)?.toInt() ?? 4,
      highlightActiveLine: json['highlightActiveLine'] as bool? ?? true,
      autoIndent: json['autoIndent'] as bool? ?? true,
    );
  }
}

/// Autosave preferences [DD §17 — Auto-Save section]
class AutosavePrefs {
  final bool enabled;
  final int delaySec;

  const AutosavePrefs({
    this.enabled = true,
    this.delaySec = 3,
  });

  AutosavePrefs copyWith({
    bool? enabled,
    int? delaySec,
  }) {
    return AutosavePrefs(
      enabled: enabled ?? this.enabled,
      delaySec: delaySec ?? this.delaySec,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'delaySec': delaySec,
      };

  factory AutosavePrefs.fromJson(Map<String, dynamic> json) {
    return AutosavePrefs(
      enabled: json['enabled'] as bool? ?? true,
      delaySec: (json['delaySec'] as num?)?.toInt() ?? 3,
    );
  }
}

/// General preferences [DD §17 — General section]
class GeneralPrefs {
  final List<String> recentFiles;
  final int maxRecentFiles;

  const GeneralPrefs({
    this.recentFiles = const [],
    this.maxRecentFiles = 10,
  });

  GeneralPrefs copyWith({
    List<String>? recentFiles,
    int? maxRecentFiles,
  }) {
    return GeneralPrefs(
      recentFiles: recentFiles ?? this.recentFiles,
      maxRecentFiles: maxRecentFiles ?? this.maxRecentFiles,
    );
  }

  Map<String, dynamic> toJson() => {
        'recentFiles': recentFiles,
        'maxRecentFiles': maxRecentFiles,
      };

  factory GeneralPrefs.fromJson(Map<String, dynamic> json) {
    return GeneralPrefs(
      recentFiles: (json['recentFiles'] as List<dynamic>?)
              ?.cast<String>()
              .toList() ??
          [],
      maxRecentFiles: (json['maxRecentFiles'] as num?)?.toInt() ?? 10,
    );
  }
}

/// Window state preferences [DD §17 — Window section]
class WindowPrefs {
  final int width;
  final int height;
  final int? x;
  final int? y;
  final bool isMaximized;

  const WindowPrefs({
    this.width = 1200,
    this.height = 800,
    this.x,
    this.y,
    this.isMaximized = false,
  });

  WindowPrefs copyWith({
    int? width,
    int? height,
    int? x,
    int? y,
    bool? isMaximized,
    bool clearX = false,
    bool clearY = false,
  }) {
    return WindowPrefs(
      width: width ?? this.width,
      height: height ?? this.height,
      x: clearX ? null : (x ?? this.x),
      y: clearY ? null : (y ?? this.y),
      isMaximized: isMaximized ?? this.isMaximized,
    );
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'x': x,
        'y': y,
        'isMaximized': isMaximized,
      };

  factory WindowPrefs.fromJson(Map<String, dynamic> json) {
    return WindowPrefs(
      width: (json['width'] as num?)?.toInt() ?? 1200,
      height: (json['height'] as num?)?.toInt() ?? 800,
      x: (json['x'] as num?)?.toInt(),
      y: (json['y'] as num?)?.toInt(),
      isMaximized: json['isMaximized'] as bool? ?? false,
    );
  }
}
