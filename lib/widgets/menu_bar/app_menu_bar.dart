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

  const AppMenuBar({
    super.key,
    required this.child,
    required this.onCommandPalette,
    required this.onFind,
    required this.onFindReplace,
    required this.onPreferences,
    required this.onPrint,
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
              onSelected: () => tabManager.saveActiveDocument(),
            ),
            PlatformMenuItem(
              label: 'Save As...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
              onSelected: () => tabManager.saveActiveDocumentAs(),
            ),
            PlatformMenuItem(
              label: 'Rename...',
              shortcut: const SingleActivator(LogicalKeyboardKey.f2),
              onSelected: onRename,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Close Tab',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyW, meta: true),
              onSelected: onCloseTab,
            ),
            PlatformMenuItem(
              label: 'Close All Tabs',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyW, meta: true, shift: true),
              onSelected: onCloseAllTabs,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Print...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyP, meta: true),
              onSelected: onPrint,
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
              onSelected: null, // Handled by re_editor
            ),
            PlatformMenuItem(
              label: 'Redo',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true),
              onSelected: null,
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Cut',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyX, meta: true),
              onSelected: null,
            ),
            PlatformMenuItem(
              label: 'Copy',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyC, meta: true),
              onSelected: null,
            ),
            PlatformMenuItem(
              label: 'Paste',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyV, meta: true),
              onSelected: null,
            ),
            PlatformMenuItem(
              label: 'Select All',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyA, meta: true),
              onSelected: null,
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
              onSelected: onFind,
            ),
            PlatformMenuItem(
              label: 'Find & Replace...',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyF, meta: true, alt: true),
              onSelected: onFindReplace,
            ),
          ],
        ),
        // View menu
        PlatformMenu(
          label: 'View',
          menus: [
            PlatformMenuItem(
              label: 'Viewer Only${viewMode == ViewMode.viewerOnly ? '  ✓' : ''}',
              onSelected: () => viewModeNotifier.setMode(ViewMode.viewerOnly),
            ),
            PlatformMenuItem(
              label: 'Split View${viewMode == ViewMode.split ? '  ✓' : ''}',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
              onSelected: () => viewModeNotifier.setMode(ViewMode.split),
            ),
            PlatformMenuItem(
              label: 'Editor Only${viewMode == ViewMode.editorOnly ? '  ✓' : ''}',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true, shift: true),
              onSelected: () => viewModeNotifier.setMode(ViewMode.editorOnly),
            ),
            const PlatformMenuItemGroup(members: []),
            PlatformMenuItem(
              label: 'Zoom In',
              shortcut: const SingleActivator(LogicalKeyboardKey.equal, meta: true),
              onSelected: onZoomIn,
            ),
            PlatformMenuItem(
              label: 'Zoom Out',
              shortcut: const SingleActivator(LogicalKeyboardKey.minus, meta: true),
              onSelected: onZoomOut,
            ),
            PlatformMenuItem(
              label: 'Reset Zoom',
              shortcut: const SingleActivator(LogicalKeyboardKey.digit0, meta: true),
              onSelected: onZoomReset,
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
                    onPressed: () => tabManager.saveActiveDocument(),
                    child: const Text('Save'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Shift+S'),
                    onPressed: () => tabManager.saveActiveDocumentAs(),
                    child: const Text('Save As...'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('F2'),
                    onPressed: onRename,
                    child: const Text('Rename...'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+W'),
                    onPressed: onCloseTab,
                    child: const Text('Close Tab'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Shift+W'),
                    onPressed: onCloseAllTabs,
                    child: const Text('Close All Tabs'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+P'),
                    onPressed: onPrint,
                    child: const Text('Print...'),
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
                    onPressed: null, // Handled by re_editor
                    child: const Text('Undo'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Shift+Z'),
                    onPressed: null,
                    child: const Text('Redo'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+X'),
                    onPressed: null,
                    child: const Text('Cut'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+C'),
                    onPressed: null,
                    child: const Text('Copy'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+V'),
                    onPressed: null,
                    child: const Text('Paste'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+A'),
                    onPressed: null,
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
                    onPressed: onFind,
                    child: const Text('Find...'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+H'),
                    onPressed: onFindReplace,
                    child: const Text('Find & Replace...'),
                  ),
                ],
                child: const Text('Search'),
              ),
              // View menu
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => viewModeNotifier.setMode(ViewMode.viewerOnly),
                    leadingIcon: viewMode == ViewMode.viewerOnly
                        ? const Icon(Icons.check, size: 16)
                        : const SizedBox(width: 16),
                    child: const Text('Viewer Only'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+E'),
                    onPressed: () => viewModeNotifier.setMode(ViewMode.split),
                    leadingIcon: viewMode == ViewMode.split
                        ? const Icon(Icons.check, size: 16)
                        : const SizedBox(width: 16),
                    child: const Text('Split View'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+Shift+E'),
                    onPressed: () => viewModeNotifier.setMode(ViewMode.editorOnly),
                    leadingIcon: viewMode == ViewMode.editorOnly
                        ? const Icon(Icons.check, size: 16)
                        : const SizedBox(width: 16),
                    child: const Text('Editor Only'),
                  ),
                  const Divider(height: 1),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+='),
                    onPressed: onZoomIn,
                    child: const Text('Zoom In'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+-'),
                    onPressed: onZoomOut,
                    child: const Text('Zoom Out'),
                  ),
                  MenuItemButton(
                    trailingIcon: _shortcutLabel('Ctrl+0'),
                    onPressed: onZoomReset,
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
