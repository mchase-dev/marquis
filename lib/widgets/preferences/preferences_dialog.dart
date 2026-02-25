import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/models/preferences_state.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/theme/app_theme.dart';

/// Preferences dialog with live-apply settings [DD §17, §20]
class PreferencesDialog extends ConsumerStatefulWidget {
  const PreferencesDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const PreferencesDialog(),
    );
  }

  @override
  ConsumerState<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends ConsumerState<PreferencesDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _hexController;
  final _hexFocusNode = FocusNode();
  bool _hexFieldHasFocus = false;

  // Preset accent colors [DD §20]
  static const _presetColors = [
    '#6C63FF', '#2196F3', '#00BCD4', '#4CAF50', '#FF9800', '#F44336',
    '#E91E63', '#9C27B0', '#795548', '#607D8B', '#009688', '#FF5722',
  ];

  // Platform-aware monospace font list
  late final List<String> _fontList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _hexController = TextEditingController();
    _hexFocusNode.addListener(() {
      setState(() => _hexFieldHasFocus = _hexFocusNode.hasFocus);
    });
    _fontList = _buildFontList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hexController.dispose();
    _hexFocusNode.dispose();
    super.dispose();
  }

  List<String> _buildFontList() {
    final fonts = <String>['JetBrains Mono'];
    if (Platform.isWindows) {
      fonts.addAll(['Consolas', 'Courier New']);
    } else if (Platform.isMacOS) {
      fonts.addAll(['Menlo', 'Monaco', 'Courier New']);
    } else {
      fonts.addAll(['DejaVu Sans Mono', 'Liberation Mono', 'Courier New']);
    }
    return fonts;
  }

  void _update(PreferencesState Function(PreferencesState) updater) {
    ref.read(preferencesProvider.notifier).updatePreferences(updater);
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(preferencesProvider);
    final prefs = prefsAsync.value;
    if (prefs == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 8, 16),
              child: Row(
                children: [
                  Text('Preferences', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Appearance'),
                Tab(text: 'Editor'),
                Tab(text: 'Auto-Save'),
              ],
            ),
            // Tab content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppearanceTab(prefs),
                  _buildEditorTab(prefs),
                  _buildAutosaveTab(prefs),
                ],
              ),
            ),
            // Reset to Defaults
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextButton(
                onPressed: () => _update((p) => p.copyWith(
                      appearance: const AppearancePrefs(),
                      editor: const EditorPrefs(),
                      autosave: const AutosavePrefs(),
                    )),
                child: const Text('Reset to Defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab: Appearance ───

  Widget _buildAppearanceTab(PreferencesState prefs) {
    final appearance = prefs.appearance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Sync hex controller when field doesn't have focus
    if (!_hexFieldHasFocus && _hexController.text != appearance.accentColor) {
      _hexController.text = appearance.accentColor;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Theme
        _buildDropdownRow<ThemeModePref>(
          label: 'Theme',
          value: appearance.theme,
          items: ThemeModePref.values,
          labelFor: (v) => switch (v) {
            ThemeModePref.light => 'Light',
            ThemeModePref.dark => 'Dark',
            ThemeModePref.system => 'System',
          },
          onChanged: (v) => _update((p) => p.copyWith(
                appearance: p.appearance.copyWith(theme: v),
              )),
        ),
        const SizedBox(height: 16),

        // Accent color
        _buildLabel('Accent Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((hex) {
            final color = AppTheme.parseHexColor(hex);
            final isSelected =
                appearance.accentColor.toUpperCase() == hex.toUpperCase();
            return _ColorSwatch(
              color: color,
              isSelected: isSelected,
              onTap: () => _update((p) => p.copyWith(
                    appearance: p.appearance.copyWith(accentColor: hex),
                  )),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Custom hex input
        Row(
          children: [
            Text('Custom:', style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _hexController,
                focusNode: _hexFocusNode,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'JetBrains Mono',
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                  hintText: '#6C63FF',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[#0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                onChanged: (value) {
                  if (_isValidHex(value)) {
                    _update((p) => p.copyWith(
                          appearance:
                              p.appearance.copyWith(accentColor: value),
                        ));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _isValidHex(_hexController.text)
                    ? AppTheme.parseHexColor(_hexController.text)
                    : AppTheme.parseHexColor(appearance.accentColor),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colorScheme.outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Viewer Font Size
        _buildSliderRow(
          label: 'Viewer Font Size',
          value: appearance.viewerFontSize.toDouble(),
          min: 10,
          max: 28,
          divisions: 18,
          suffix: '${appearance.viewerFontSize}px',
          onChanged: (v) => _update((p) => p.copyWith(
                appearance:
                    p.appearance.copyWith(viewerFontSize: v.round()),
              )),
        ),

        // Zoom
        _buildSliderRow(
          label: 'Zoom',
          value: appearance.zoomLevel.toDouble(),
          min: 50,
          max: 200,
          divisions: 15,
          suffix: '${appearance.zoomLevel}%',
          onChanged: (v) {
            final snapped = (v / 10).round() * 10;
            _update((p) => p.copyWith(
                  appearance:
                      p.appearance.copyWith(zoomLevel: snapped),
                ));
          },
        ),
      ],
    );
  }

  // ─── Tab: Editor ───

  Widget _buildEditorTab(PreferencesState prefs) {
    final editor = prefs.editor;
    final appearance = prefs.appearance;

    // Ensure stored font is in the list
    final fontList = _fontList.contains(appearance.editorFontFamily)
        ? _fontList
        : [appearance.editorFontFamily, ..._fontList];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Editor Font
        _buildDropdownRow<String>(
          label: 'Font',
          value: appearance.editorFontFamily,
          items: fontList,
          labelFor: (v) => v,
          fontFamily: (v) => v,
          onChanged: (v) => _update((p) => p.copyWith(
                appearance:
                    p.appearance.copyWith(editorFontFamily: v),
              )),
        ),
        const SizedBox(height: 8),

        // Editor Font Size
        _buildSliderRow(
          label: 'Font Size',
          value: appearance.editorFontSize.toDouble(),
          min: 10,
          max: 28,
          divisions: 18,
          suffix: '${appearance.editorFontSize}px',
          onChanged: (v) => _update((p) => p.copyWith(
                appearance:
                    p.appearance.copyWith(editorFontSize: v.round()),
              )),
        ),
        const SizedBox(height: 4),

        _buildSwitchRow(
          label: 'Word Wrap',
          value: editor.wordWrap,
          onChanged: (v) => _update((p) => p.copyWith(
                editor: p.editor.copyWith(wordWrap: v),
              )),
        ),
        _buildSwitchRow(
          label: 'Show Line Numbers',
          value: editor.showLineNumbers,
          onChanged: (v) => _update((p) => p.copyWith(
                editor: p.editor.copyWith(showLineNumbers: v),
              )),
        ),

        // Tab Size
        _buildSliderRow(
          label: 'Tab Size',
          value: editor.tabSize.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          suffix: '${editor.tabSize}',
          onChanged: (v) => _update((p) => p.copyWith(
                editor: p.editor.copyWith(tabSize: v.round()),
              )),
        ),

        _buildSwitchRow(
          label: 'Highlight Active Line',
          value: editor.highlightActiveLine,
          onChanged: (v) => _update((p) => p.copyWith(
                editor: p.editor.copyWith(highlightActiveLine: v),
              )),
        ),
        _buildSwitchRow(
          label: 'Auto-Indent',
          value: editor.autoIndent,
          onChanged: (v) => _update((p) => p.copyWith(
                editor: p.editor.copyWith(autoIndent: v),
              )),
        ),
      ],
    );
  }

  // ─── Tab: Auto-Save ───

  Widget _buildAutosaveTab(PreferencesState prefs) {
    final autosave = prefs.autosave;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildSwitchRow(
          label: 'Auto-save',
          value: autosave.enabled,
          onChanged: (v) => _update((p) => p.copyWith(
                autosave: p.autosave.copyWith(enabled: v),
              )),
        ),

        // Delay slider — disabled when autosave is off
        _buildSliderRow(
          label: 'Delay',
          value: autosave.delaySec.toDouble(),
          min: 1,
          max: 30,
          divisions: 29,
          suffix: '${autosave.delaySec}s',
          enabled: autosave.enabled,
          onChanged: (v) => _update((p) => p.copyWith(
                autosave: p.autosave.copyWith(delaySec: v.round()),
              )),
        ),
      ],
    );
  }

  // ─── Helpers ───

  bool _isValidHex(String value) {
    if (!value.startsWith('#') || value.length != 7) return false;
    final hex = value.substring(1);
    return RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex);
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildDropdownRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelFor,
    String Function(T)? fontFamily,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildLabel(label)),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: items
                .map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        labelFor(item),
                        style: fontFamily != null
                            ? TextStyle(fontFamily: fontFamily(item))
                            : null,
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    bool enabled = true,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildLabel(label)),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      divisions: divisions,
                      onChanged: enabled ? onChanged : null,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    suffix,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: enabled
                              ? null
                              : Theme.of(context).disabledColor,
                        ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Expanded(child: _buildLabel(label)),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Color swatch circle ───

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 2.5,
                )
              : Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
        ),
        child: isSelected
            ? Icon(Icons.check, size: 14, color: _contrastColor(color))
            : null,
      ),
    );
  }

  static Color _contrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
