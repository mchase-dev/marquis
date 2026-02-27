import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/providers/tab_manager_provider.dart';
import 'package:marquis/providers/view_mode_provider.dart';

/// Platform-adaptive menu bar [DD §12]
///
/// macOS: PlatformMenuBar (native system menu)
/// Windows/Linux: MenuBar widget (in-app)
class AppMenuBar extends ConsumerWidget {
  final Widget child;
  final VoidCallback onCommandPalette;
  final VoidCallback onFind;
  final VoidCallback onFindReplace;
  final VoidCallback onPreferences;
  final VoidCallback onPrint;
  final VoidCallback onExportPdf;
  final VoidCallback onRename;
  final VoidCallback onAbout;
  final VoidCallback onUserGuide;
  final VoidCallback onMarkdownReference;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomReset;
  final VoidCallback onCloseTab;
  final VoidCallback onCloseAllTabs;
  final VoidCallback onQuit;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onSelectAll;

  const AppMenuBar({
    super.key,
    required this.child,
    required this.onCommandPalette,
    required this.onFind,
    required this.onFindReplace,
    required this.onPreferences,
    required this.onPrint,
    required this.onExportPdf,
    required this.onRename,
    required this.onAbout,
    required this.onUserGuide,
    required this.onMarkdownReference,
    required this.onToggleFullScreen,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomReset,
    required this.onCloseTab,
    required this.onCloseAllTabs,
    required this.onQuit,
    this.onUndo,
    this.onRedo,
    this.onCut,
    this.onCopy,
    this.onPaste,
    this.onSelectAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Platform.isMacOS) {
      return _buildMacOSMenu(context, ref);
    }
    return _buildDesktopMenu(context, ref);
  }

  /// macOS: native system menu bar [DD §12 — macOS Considerations]
  Widget _buildMacOSMenu(BuildContext context, WidgetRef ref) {
    final tabManager = ref.read(tabManagerProvider.notifier);
    final viewModeNotifier = ref.read(viewModeProvider.notifier);
    final viewMode = ref.watch(viewModeProvider);
    final recentFiles = ref.watch(preferencesProvider).value?.general.recentFiles ?? [];
    final hasActiveTab = ref.watch(tabManagerProvider).hasTabs;

    return PlatformMenuBar(
      menus: [
        // App menu (macOS only)
        PlatformMenu(
          label: 'Marquis',
          menus: [
            PlatformMenuItem(
              label: 'About Marquis',
              onSelected: onAbout,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Preferences...',
              shortcut: const SingleActivator(LogicalKeyboardKey.comma, meta: true),
              onSelected: onPreferences,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Quit Marquis',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
              onSelected: onQuit,
            ),
          ],
        ),
        // File menu
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: 'New',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true),
              onSelected: () => tabManager.newFile(),
            ),
            PlatformMenuItem(
              label: 'Open...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
              onSelected: () => tabManager.openFileDialog(),
            ),
            if (recentFiles.isNotEmpty)
              PlatformMenu(
                label: 'Open Recent',
                menus: [
                  ...recentFiles.map((path) => PlatformMenuItem(
                        label: path.split(RegExp(r'[/\\]')).last,
                        onSelected: () => tabManager.openFile(path),
                      )),
                  const PlatformMenuItemGroup(members: []),
                  PlatformMenuItem(
                    label: 'Clear Recent',
                    onSelected: () => ref.read(preferencesProvider.notifier).clearRecentFiles(),
                  ),
                ],
              ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Save',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
              onSelected: hasActiveTab ? () => tabManager.saveActiveDocument() : null,
            ),
            PlatformMenuItem(
              label: 'Save As...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
              onSelected: hasActiveTab ? () => tabManager.saveActiveDocumentAs() : null,
            ),
            PlatformMenuItem(
              label: 'Rename...',
              shortcut: const SingleActivator(LogicalKeyboardKey.f2),
              onSelected: hasActiveTab ? onRename : null,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Close Tab',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyW, meta: true),
              onSelected: hasActiveTab ? onCloseTab : null,
            ),
            PlatformMenuItem(
              label: 'Close All Tabs',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyW, meta: true, shift: true),
              onSelected: hasActiveTab ? onCloseAllTabs : null,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Print...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyP, meta: true),
              onSelected: hasActiveTab ? onPrint : null,
            ),
            PlatformMenuItem(
              label: 'Export to PDF...',
              onSelected: hasActiveTab ? onExportPdf : null,
            ),
          ],
        ),
        // Edit menu
        PlatformMenu(
          label: 'Edit',
          menus: [
            PlatformMenuItem(
              label: 'Edit Mode On/Off',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
              onSelected: () => viewModeNotifier.toggleEdit(),
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Undo',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
              onSelected: onUndo,
            ),
            PlatformMenuItem(
              label: 'Redo',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true),
              onSelected: onRedo,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Cut',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyX, meta: true),
              onSelected: onCut,
            ),
            PlatformMenuItem(
              label: 'Copy',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyC, meta: true),
              onSelected: onCopy,
            ),
            PlatformMenuItem(
              label: 'Paste',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyV, meta: true),
              onSelected: onPaste,
            ),
            PlatformMenuItem(
              label: 'Select All',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyA, meta: true),
              onSelected: onSelectAll,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Command Palette...',
              shortcut: const SingleActivator(LogicalKeyboardKey.slash, meta: true),
              onSelected: onCommandPalette,
            ),
          ],
        ),
        // Search menu
        PlatformMenu(
          label: 'Search',
          menus: [
            PlatformMenuItem(
              label: 'Find...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyF, meta: true),
              onSelected: hasActiveTab ? onFind : null,
            ),
            PlatformMenuItem(
              label: 'Find & Replace...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyF, meta: true, alt: true),
              onSelected: hasActiveTab ? onFindReplace : null,
            ),
          ],
        ),
        // View menu
        PlatformMenu(
          label: 'View',
          menus: [
            PlatformMenuItem(
              label: 'Viewer Only${viewMode == ViewMode.viewerOnly ? '  ✓' : ''}',
              onSelected: hasActiveTab ? () => viewModeNotifier.setMode(ViewMode.viewerOnly) : null,
            ),
            PlatformMenuItem(
              label: 'Split View${viewMode == ViewMode.split ? '  ✓' : ''}',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
              onSelected: hasActiveTab ? () => viewModeNotifier.setMode(ViewMode.split) : null,
            ),
            PlatformMenuItem(
              label: 'Editor Only${viewMode == ViewMode.editorOnly ? '  ✓' : ''}',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true, shift: true),
              onSelected: hasActiveTab ? () => viewModeNotifier.setMode(ViewMode.editorOnly) : null,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Zoom In',
              shortcut: const SingleActivator(LogicalKeyboardKey.equal, meta: true),
              onSelected: hasActiveTab ? onZoomIn : null,
            ),
            PlatformMenuItem(
              label: 'Zoom Out',
              shortcut: const SingleActivator(LogicalKeyboardKey.minus, meta: true),
              onSelected: hasActiveTab ? onZoomOut : null,
            ),
            PlatformMenuItem(
              label: 'Reset Zoom',
              shortcut: const SingleActivator(LogicalKeyboardKey.digit0, meta: true),
              onSelected: hasActiveTab ? onZoomReset : null,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Full Screen',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyF, meta: true, control: true),
              onSelected: onToggleFullScreen,
            ),
          ],
        ),
        // Help menu
        PlatformMenu(
          label: 'Help',
          menus: [
            PlatformMenuItem(
              label: 'User Guide',
              onSelected: onUserGuide,
            ),
            PlatformMenuItem(
              label: 'Markdown Reference',
              onSelected: onMarkdownReference,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'About Marquis',
              onSelected: onAbout,
            ),
          ],
        ),
      ],
      child: child,
    );
  }

  /// Shortcut label widget for menu items (display only, no registration)
  static Widget _shortcutLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  /// Windows/Linux: in-app MenuBar widget [DD §12]
  ///
  /// Shortcut labels are display-only (trailingIcon) — actual shortcut
  /// handling is done by CallbackShortcuts in AppShell to avoid conflicts
  /// with MenuBar's ShortcutRegistrar.
  Widget _buildDesktopMenu(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tabManager = ref.read(tabManagerProvider.notifier);
    final viewModeNotifier = ref.read(viewModeProvider.notifier);
    final viewMode = ref.watch(viewModeProvider);
    final recentFiles = ref.watch(preferencesProvider).value?.general.recentFiles ?? [];
    final hasActiveTab = ref.watch(tabManagerProvider).hasTabs;

    return Column(
      children: [
        Container(
          height: 32,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          child: MenuBar(
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerLow),
              elevation: const WidgetStatePropertyAll(0),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
              alignment: Alignment.centerLeft,
            ),
            children: [
              // File menu
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+N'),
                    onPressed: () => tabManager.newFile(),
                    child: const Text('New'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+O'),
                    onPressed: () => tabManager.openFileDialog(),
                    child: const Text('Open...'),
                  ),
                  if (recentFiles.isNotEmpty)
                    SubmenuButton(
                      menuChildren: [
                        ...recentFiles.map((path) => MenuItemButton(
                              onPressed: () => tabManager.openFile(path),
                              child: Text(
                                path.split(RegExp(r'[/\\]')).last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                        const Divider(height: 1),
                        MenuItemButton(
                          onPressed: () => ref.read(preferencesProvider.notifier).clearRecentFiles(),
                          child: const Text('Clear Recent'),
                        ),
                      ],
                      child: const Text('Open Recent'),
                    ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+S'),
                    onPressed: hasActiveTab ? () => tabManager.saveActiveDocument() : null,
                    child: const Text('Save'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Shift+S'),
                    onPressed: hasActiveTab ? () => tabManager.saveActiveDocumentAs() : null,
                    child: const Text('Save As...'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('F2'),
                    onPressed: hasActiveTab ? onRename : null,
                    child: const Text('Rename...'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+W'),
                    onPressed: hasActiveTab ? onCloseTab : null,
                    child: const Text('Close Tab'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Shift+W'),
                    onPressed: hasActiveTab ? onCloseAllTabs : null,
                    child: const Text('Close All Tabs'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+P'),
                    onPressed: hasActiveTab ? onPrint : null,
                    child: Text(Platform.isWindows ? 'View as PDF...' : 'Print...'),
                  ),
                  MenuItemButton(
                    onPressed: hasActiveTab ? onExportPdf : null,
                    child: const Text('Export to PDF...'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+,'),
                    onPressed: onPreferences,
                    child: const Text('Preferences...'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Q'),
                    onPressed: onQuit,
                    child: const Text('Quit'),
                  ),
                ],
                child: const Text('File'),
              ),
              // Edit menu
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+E'),
                    onPressed: () => viewModeNotifier.toggleEdit(),
                    child: const Text('Edit Mode On/Off'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Z'),
                    onPressed: onUndo,
                    child: const Text('Undo'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Shift+Z'),
                    onPressed: onRedo,
                    child: const Text('Redo'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+X'),
                    onPressed: onCut,
                    child: const Text('Cut'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+C'),
                    onPressed: onCopy,
                    child: const Text('Copy'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+V'),
                    onPressed: onPaste,
                    child: const Text('Paste'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+A'),
                    onPressed: onSelectAll,
                    child: const Text('Select All'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+/'),
                    onPressed: onCommandPalette,
                    child: const Text('Command Palette...'),
                  ),
                ],
                child: const Text('Edit'),
              ),
              // Search menu
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+F'),
                    onPressed: hasActiveTab ? onFind : null,
                    child: const Text('Find...'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+H'),
                    onPressed: hasActiveTab ? onFindReplace : null,
                    child: const Text('Find & Replace...'),
                  ),
                ],
                child: const Text('Search'),
              ),
              // View menu
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: hasActiveTab ? () => viewModeNotifier.setMode(ViewMode.viewerOnly) : null,
                    leadingIcon: viewMode == ViewMode.viewerOnly
                        ? const Icon(Icons.check, size: 16)
                        : const SizedBox(width: 16),
                    child: const Text('Viewer Only'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+E'),
                    onPressed: hasActiveTab ? () => viewModeNotifier.setMode(ViewMode.split) : null,
                    leadingIcon: viewMode == ViewMode.split
                        ? const Icon(Icons.check, size: 16)
                        : const SizedBox(width: 16),
                    child: const Text('Split View'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Shift+E'),
                    onPressed: hasActiveTab ? () => viewModeNotifier.setMode(ViewMode.editorOnly) : null,
                    leadingIcon: viewMode == ViewMode.editorOnly
                        ? const Icon(Icons.check, size: 16)
                        : const SizedBox(width: 16),
                    child: const Text('Editor Only'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+='),
                    onPressed: hasActiveTab ? onZoomIn : null,
                    child: const Text('Zoom In'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+-'),
                    onPressed: hasActiveTab ? onZoomOut : null,
                    child: const Text('Zoom Out'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+0'),
                    onPressed: hasActiveTab ? onZoomReset : null,
                    child: const Text('Reset Zoom'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('F11'),
                    onPressed: onToggleFullScreen,
                    child: const Text('Full Screen'),
                  ),
                ],
                child: const Text('View'),
              ),
              // Help menu
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: onUserGuide,
                    child: const Text('User Guide'),
                  ),
                  MenuItemButton(
                    onPressed: onMarkdownReference,
                    child: const Text('Markdown Reference'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    onPressed: onAbout,
                    child: const Text('About Marquis'),
                  ),
                ],
                child: const Text('Help'),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
