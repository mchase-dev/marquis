import 'package:flutter/material.dart';

import 'package:marquis/core/constants.dart';
import 'package:marquis/providers/view_mode_provider.dart';

/// Split view container with editor left and viewer right [DD §10]
class SplitView extends StatefulWidget {
  final ViewMode viewMode;
  final Widget editor;
  final Widget viewer;

  const SplitView({
    super.key,
    required this.viewMode,
    required this.editor,
    required this.viewer,
  });

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  /// Editor fraction of total width (0.0 to 1.0)
  double _editorFraction = 0.5;

  static const _dividerWidth = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final minFraction = AppConstants.minPaneWidth / totalWidth;
        final maxFraction = 1.0 - minFraction;

        final showEditor =
            widget.viewMode == ViewMode.split || widget.viewMode == ViewMode.editorOnly;
        final showViewer =
            widget.viewMode == ViewMode.split || widget.viewMode == ViewMode.viewerOnly;
        final showDivider = widget.viewMode == ViewMode.split;

        // Calculate pane widths based on view mode
        double editorWidth;
        double viewerWidth;
        switch (widget.viewMode) {
          case ViewMode.viewerOnly:
            editorWidth = 0;
            viewerWidth = totalWidth;
          case ViewMode.split:
            final fraction = _editorFraction.clamp(minFraction, maxFraction);
            final usableWidth = totalWidth - _dividerWidth;
            editorWidth = fraction * usableWidth;
            viewerWidth = usableWidth - editorWidth;
          case ViewMode.editorOnly:
            editorWidth = totalWidth;
            viewerWidth = 0;
        }

        return Row(
          children: [
            // Editor pane — only mount when visible (re_editor requires width > 0)
            if (showEditor)
              SizedBox(
                width: editorWidth,
                child: widget.editor,
              ),
            // Draggable divider [DD §10 — Resizable Divider]
            if (showDivider)
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _editorFraction += details.delta.dx / (totalWidth - _dividerWidth);
                    _editorFraction =
                        _editorFraction.clamp(minFraction, maxFraction);
                  });
                },
                onDoubleTap: () {
                  setState(() => _editorFraction = 0.5);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: _dividerWidth,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 4, // 4px visible [DD §10]
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                ),
              ),
            // Viewer pane — only mount when visible
            if (showViewer)
              SizedBox(
                width: viewerWidth,
                child: widget.viewer,
              ),
          ],
        );
      },
    );
  }
}
