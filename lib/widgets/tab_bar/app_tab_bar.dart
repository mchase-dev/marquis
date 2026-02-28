import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/providers/tab_manager_provider.dart';
import 'package:marquis/providers/view_mode_provider.dart';
import 'package:marquis/widgets/tab_bar/tab_item.dart';

/// Horizontal tab strip with view mode selector
class AppTabBar extends ConsumerStatefulWidget {
  const AppTabBar({super.key});

  @override
  ConsumerState<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends ConsumerState<AppTabBar> {
  final _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollState);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollState);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollState() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final left = pos.pixels > 0;
    final right = pos.pixels < pos.maxScrollExtent - 1;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  void _scrollLeft() {
    final pos = _scrollController.position;
    _scrollController.animateTo(
      (pos.pixels - 150).clamp(0, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    final pos = _scrollController.position;
    _scrollController.animateTo(
      (pos.pixels + 150).clamp(0, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabManagerProvider);
    final tabManager = ref.read(tabManagerProvider.notifier);
    final theme = Theme.of(context);
    final viewMode = ref.watch(viewModeProvider);

    if (!tabState.hasTabs) {
      return const SizedBox.shrink();
    }

    // Check overflow after layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left scroll arrow
          if (_canScrollLeft)
            _ScrollArrow(
              icon: Icons.chevron_left,
              onPressed: _scrollLeft,
            ),
          // Tab list
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              scrollController: _scrollController,
              buildDefaultDragHandles: false,
              itemCount: tabState.tabIds.length,
              onReorder: tabManager.reorderTabs,
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 4,
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final tabId = tabState.tabIds[index];
                final doc = tabManager.getDocument(tabId);
                if (doc == null) return SizedBox.shrink(key: ValueKey(tabId));

                return ReorderableDragStartListener(
                  key: ValueKey(tabId),
                  index: index,
                  child: TabItem(
                    tabId: tabId,
                    displayName: doc.displayName,
                    isDirty: doc.isDirty,
                    isActive: index == tabState.activeTabIndex,
                    isConflict: doc.isExternallyModified,
                    onTap: () => tabManager.setActiveTab(index),
                    onClose: () => _handleCloseTab(context, ref, tabId),
                  ),
                );
              },
            ),
          ),
          // Right scroll arrow
          if (_canScrollRight)
            _ScrollArrow(
              icon: Icons.chevron_right,
              onPressed: _scrollRight,
            ),
          // View mode selector
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 6),
            child: SegmentedButton<ViewMode>(
              segments: const [
                ButtonSegment(
                  value: ViewMode.viewerOnly,
                  icon: Icon(Icons.visibility_outlined, size: 14),
                  tooltip: 'Viewer Only',
                ),
                ButtonSegment(
                  value: ViewMode.split,
                  icon: Icon(Icons.vertical_split_outlined, size: 14),
                  tooltip: 'Split View',
                ),
                ButtonSegment(
                  value: ViewMode.editorOnly,
                  icon: Icon(Icons.edit_note_outlined, size: 14),
                  tooltip: 'Editor Only',
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (selected) {
                ref.read(viewModeProvider.notifier).setMode(selected.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 6),
                ),
                minimumSize: WidgetStateProperty.all(const Size(0, 26)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCloseTab(BuildContext context, WidgetRef ref, String tabId) {
    final tabManager = ref.read(tabManagerProvider.notifier);
    final doc = tabManager.getDocument(tabId);

    if (doc != null && doc.isDirty) {
      _showSavePrompt(context, ref, tabId, doc.displayName);
    } else {
      tabManager.closeTab(tabId);
    }
  }

  Future<void> _showSavePrompt(
    BuildContext context,
    WidgetRef ref,
    String tabId,
    String displayName,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save changes?'),
        content: Text(
            'Do you want to save changes to "$displayName" before closing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text("Don't Save"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result == 'cancel') return;

    final tabManager = ref.read(tabManagerProvider.notifier);
    if (result == 'save') {
      final saved = await tabManager.saveDocument(tabId);
      if (!saved) return;
    }
    tabManager.closeTab(tabId);
  }
}

/// Arrow button for scrolling overflowed tabs — uses a tinted background
/// and the accent color so it stands out from the tab strip.
class _ScrollArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ScrollArrow({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 28,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        border: Border(
          left: icon == Icons.chevron_right
              ? BorderSide(color: theme.dividerColor, width: 0.5)
              : BorderSide.none,
          right: icon == Icons.chevron_left
              ? BorderSide(color: theme.dividerColor, width: 0.5)
              : BorderSide.none,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: theme.colorScheme.primary),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: icon == Icons.chevron_left ? 'Scroll left' : 'Scroll right',
      ),
    );
  }
}
