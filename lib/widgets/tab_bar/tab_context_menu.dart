import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Context menu items for right-clicking a tab
class TabContextMenu {
  TabContextMenu._();

  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required String tabId,
    required String? filePath,
    required VoidCallback onClose,
    required VoidCallback onCloseOthers,
    required VoidCallback onCloseAll,
    required VoidCallback onCloseToRight,
  }) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(value: 'close', child: Text('Close')),
        const PopupMenuItem(
            value: 'closeOthers', child: Text('Close Others')),
        const PopupMenuItem(value: 'closeAll', child: Text('Close All')),
        const PopupMenuItem(
            value: 'closeRight', child: Text('Close to the Right')),
        if (filePath != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'copyPath', child: Text('Copy Path')),
          const PopupMenuItem(
              value: 'reveal', child: Text('Reveal in File Explorer')),
        ],
      ],
    );

    switch (result) {
      case 'close':
        onClose();
      case 'closeOthers':
        onCloseOthers();
      case 'closeAll':
        onCloseAll();
      case 'closeRight':
        onCloseToRight();
      case 'copyPath':
        if (filePath != null) {
          await Clipboard.setData(ClipboardData(text: filePath));
        }
      case 'reveal':
        if (filePath != null) {
          _revealInExplorer(filePath);
        }
    }
  }

  static void _revealInExplorer(String path) {
    final dir = File(path).parent.path;
    if (Platform.isWindows) {
      Process.run('explorer', ['/select,', path]);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-R', path]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [dir]);
    }
  }
}
