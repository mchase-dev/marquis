import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/providers/tab_manager_provider.dart';
import 'package:marquis/widgets/tab_bar/tab_item.dart';

/// Horizontal tab strip showing open files [DD §6]
class AppTabBar extends ConsumerWidget {
  const AppTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabManagerProvider);
    final tabManager = ref.read(tabManagerProvider.notifier);

    if (!tabState.hasTabs) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
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
