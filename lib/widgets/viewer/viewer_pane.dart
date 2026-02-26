import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'package:marquis/providers/hovered_link_provider.dart';
import 'package:marquis/providers/preferences_provider.dart';
import 'package:marquis/providers/show_viewer_images_provider.dart';
import 'package:marquis/theme/viewer_theme.dart';
import 'package:marquis/widgets/viewer/viewer_find_bar.dart';

/// Error boundary widget that catches rendering errors and shows fallback [DD §24]
class _MarkdownErrorBoundary extends StatefulWidget {
  final Widget child;
  final String rawContent;

  const _MarkdownErrorBoundary({
    required this.child,
    required this.rawContent,
  });

  @override
  State<_MarkdownErrorBoundary> createState() => _MarkdownErrorBoundaryState();
}

class _MarkdownErrorBoundaryState extends State<_MarkdownErrorBoundary> {
  bool _hasError = false;

  @override
  void didUpdateWidget(_MarkdownErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state when content changes — new content might render fine
    if (oldWidget.rawContent != widget.rawContent) {
      _hasError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallback(context);
    }

    // Wrap the child in an ErrorWidget.builder override scoped to this subtree
    return _ErrorCatcher(
      onError: () {
        if (mounted) setState(() => _hasError = true);
      },
      child: widget.child,
    );
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.errorContainer,
          child: Text(
            'Markdown rendering error — showing raw text',
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              widget.rawContent,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Catches errors from a child widget subtree during build/layout/paint.
class _ErrorCatcher extends StatefulWidget {
  final VoidCallback onError;
  final Widget child;

  const _ErrorCatcher({required this.onError, required this.child});

  @override
  State<_ErrorCatcher> createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<_ErrorCatcher> {
  @override
  Widget build(BuildContext context) {
    // Use a Builder so that ErrorWidget.builder override applies to the subtree
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Schedule the callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onError();
      });
      return const SizedBox.shrink();
    };
    return widget.child;
  }

  @override
  void dispose() {
    // Restore default error widget builder
    ErrorWidget.builder = ErrorWidget.new;
    super.dispose();
  }
}

/// Rendered Markdown viewer [DD §9]
class ViewerPane extends ConsumerStatefulWidget {
  final String content;
  final String? filePath;
  final ScrollController? scrollController;

  const ViewerPane({
    super.key,
    required this.content,
    this.filePath,
    this.scrollController,
  });

  @override
  ConsumerState<ViewerPane> createState() => ViewerPaneState();
}

class ViewerPaneState extends ConsumerState<ViewerPane> {
  bool _showFindBar = false;
  Map<String, GlobalKey> _anchorKeys = {};

  /// Open viewer find bar (Ctrl+F in viewer context) [DD §16]
  void showFind() {
    setState(() => _showFindBar = true);
  }

  /// Close viewer find bar
  void closeFindBar() {
    setState(() => _showFindBar = false);
  }

  void _scrollToFraction(double fraction) {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    final target = fraction * controller.position.maxScrollExtent;
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  /// Generate a GFM-compatible anchor slug from heading text.
  static String _generateSlug(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  /// Scroll the viewer to the heading matching [slug].
  void _scrollToAnchor(String slug) {
    final key = _anchorKeys[slug];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Build a widget for a markdown image, resolving local paths relative to
  /// the document directory.
  Widget _buildImage(String url, Map<String, String> attributes) {
    final alt = attributes['alt'] ?? '';

    // Network images
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        errorBuilder: (_, error, stackTrace) => _buildImageError(alt, url),
      );
    }

    // Resolve relative paths against the document's directory
    String resolvedPath = url;
    if (!p.isAbsolute(url) && widget.filePath != null) {
      resolvedPath = p.normalize(p.join(p.dirname(widget.filePath!), url));
    }

    final file = File(resolvedPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        errorBuilder: (_, error, stackTrace) => _buildImageError(alt, url),
      );
    }

    return _buildImageError(alt, url);
  }

  Widget _buildImageError(String alt, String url) {
    return Tooltip(
      message: url,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 24),
          if (alt.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(alt),
          ],
        ],
      ),
    );
  }

  /// Collapsible image: shows a compact placeholder that expands on click.
  Widget _buildCollapsibleImage(String url, Map<String, String> attributes) {
    return _CollapsibleImage(
      url: url,
      attributes: attributes,
      imageBuilder: _buildImage,
      filePath: widget.filePath,
    );
  }

  static final _htmlCommentRe = RegExp(r'<!--[\s\S]*?-->', multiLine: true);

  /// Build markdown widgets manually so we can attach GlobalKeys to headings.
  Widget _buildMarkdownColumn(String content, MarkdownConfig config, {required bool showImages}) {
    // Strip HTML comments before rendering [DD §9]
    content = content.replaceAll(_htmlCommentRe, '');

    List<Toc> tocEntries = [];

    // Add custom image builder that resolves local file paths.
    final configWithImages = config.copy(configs: [
      ImgConfig(builder: showImages ? _buildImage : _buildCollapsibleImage),
    ]);

    final generator = MarkdownGenerator(
      generators: [
        SpanNodeGeneratorWithTag(
          tag: MarkdownTag.a.name,
          generator: (e, config, visitor) => _HoverableLinkNode(
            e.attributes,
            config.a,
            onHoverChanged: (url) =>
                ref.read(hoveredLinkProvider.notifier).set(url),
            onAnchorTap: _scrollToAnchor,
          ),
        ),
      ],
    );

    final widgets = generator.buildWidgets(
      content,
      config: configWithImages,
      onTocList: (list) => tocEntries = list,
    );

    // Map heading slugs to GlobalKeys and wrap heading widgets.
    _anchorKeys = {};
    final slugCounts = <String, int>{};
    final wrappedWidgets = List<Widget>.from(widgets);

    for (final toc in tocEntries) {
      final text = toc.node.childrenSpan.toPlainText();
      var slug = _generateSlug(text);
      if (slug.isEmpty) continue;

      // Deduplicate slugs (GFM style: heading, heading-1, heading-2).
      if (slugCounts.containsKey(slug)) {
        slugCounts[slug] = slugCounts[slug]! + 1;
        slug = '$slug-${slugCounts[slug]}';
      } else {
        slugCounts[slug] = 0;
      }

      final key = GlobalKey();
      _anchorKeys[slug] = key;

      if (toc.widgetIndex < wrappedWidgets.length) {
        wrappedWidgets[toc.widgetIndex] = SizedBox(
          key: key,
          width: double.infinity,
          child: wrappedWidgets[toc.widgetIndex],
        );
      }
    }

    return SelectionArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: wrappedWidgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showImages = ref.watch(showViewerImagesProvider);
    final prefs = ref.watch(preferencesProvider).value;
    final fontSize = prefs?.appearance.viewerFontSize.toDouble() ?? 16;
    final zoomLevel = prefs?.appearance.zoomLevel ?? 100;
    final effectiveFontSize = fontSize * zoomLevel / 100;

    final config = isDark
        ? ViewerTheme.dark(fontSize: effectiveFontSize)
        : ViewerTheme.light(fontSize: effectiveFontSize);

    return Column(
      children: [
        if (_showFindBar)
          ViewerFindBar(
            content: widget.content,
            onScrollToMatch: _scrollToFraction,
            onClose: closeFindBar,
          ),
        Expanded(
          child: widget.content.isEmpty
              ? Center(
                  child: Text(
                    'Empty document',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : _MarkdownErrorBoundary(
                  rawContent: widget.content,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SingleChildScrollView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                      child: _buildMarkdownColumn(widget.content, config, showImages: showImages),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Image widget that toggles between a compact placeholder and the full image.
class _CollapsibleImage extends StatefulWidget {
  final String url;
  final Map<String, String> attributes;
  final Widget Function(String url, Map<String, String> attributes) imageBuilder;
  final String? filePath;

  const _CollapsibleImage({
    required this.url,
    required this.attributes,
    required this.imageBuilder,
    this.filePath,
  });

  @override
  State<_CollapsibleImage> createState() => _CollapsibleImageState();
}

class _CollapsibleImageState extends State<_CollapsibleImage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_expanded) {
      return SelectionContainer.disabled(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: widget.imageBuilder(widget.url, widget.attributes),
          ),
        ),
      );
    }

    final alt = widget.attributes['alt'] ?? '';
    final label = alt.isNotEmpty ? alt : p.basename(widget.url);
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _expanded = true),
          child: Tooltip(
            message: widget.url,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image, size: 16,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Link node that reports hover state for status bar URL preview.
class _HoverableLinkNode extends ElementNode {
  final Map<String, String> attributes;
  final LinkConfig linkConfig;
  final ValueChanged<String?> onHoverChanged;
  final ValueChanged<String>? onAnchorTap;

  _HoverableLinkNode(this.attributes, this.linkConfig,
      {required this.onHoverChanged, this.onAnchorTap});

  @override
  InlineSpan build() {
    final url = attributes['href'] ?? '';
    return TextSpan(children: [
      for (final child in children)
        _toHoverableLinkSpan(
          child.build(),
          onTap: () => _onLinkTap(url),
          onEnter: (_) => onHoverChanged(url),
          onExit: (_) => onHoverChanged(null),
        ),
      if (children.isNotEmpty) const TextSpan(text: ' '),
    ]);
  }

  void _onLinkTap(String url) {
    if (url.startsWith('#')) {
      onAnchorTap?.call(url.substring(1));
      return;
    }
    if (linkConfig.onTap != null) {
      linkConfig.onTap?.call(url);
    } else {
      launchUrl(Uri.parse(url));
    }
  }

  @override
  TextStyle get style =>
      parentStyle?.merge(linkConfig.style) ?? linkConfig.style;
}

/// Wraps an [InlineSpan] with tap, enter, and exit callbacks.
InlineSpan _toHoverableLinkSpan(
  InlineSpan span, {
  required VoidCallback onTap,
  required void Function(PointerEvent) onEnter,
  required void Function(PointerEvent) onExit,
}) {
  if (span is TextSpan) {
    return TextSpan(
      text: span.text,
      children: span.children
          ?.map((e) => _toHoverableLinkSpan(e,
              onTap: onTap, onEnter: onEnter, onExit: onExit))
          .toList(),
      style: span.style,
      recognizer: TapGestureRecognizer()..onTap = onTap,
      onEnter: onEnter,
      onExit: onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  } else if (span is WidgetSpan) {
    return WidgetSpan(
      child: MouseRegion(
        onEnter: onEnter,
        onExit: onExit,
        child: InkWell(onTap: onTap, child: span.child),
      ),
      alignment: span.alignment,
      baseline: span.baseline,
      style: span.style,
    );
  }
  return span;
}
