import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Converts parsed Markdown AST nodes into PDF widgets.
///
/// Walks the AST from the `markdown` package using [md.NodeVisitor] and
/// produces [pw.Widget] objects suitable for inclusion in a [pw.MultiPage].
class MarkdownPdfRenderer implements md.NodeVisitor {
  MarkdownPdfRenderer({
    required this.monoFont,
    required this.monoBoldFont,
    required this.symbolsFont,
    required this.emojiFont,
    this.fontSize = 16,
    this.images = const {},
  });

  final pw.Font monoFont;
  final pw.Font monoBoldFont;
  final pw.Font symbolsFont;
  final pw.Font emojiFont;
  final double fontSize;
  final Map<String, pw.MemoryImage> images;

  // ── State ──────────────────────────────────────────────────────────────

  /// Stack of widget accumulators. Bottom = top-level output.
  /// Nested block elements (blockquote, li) push/pop layers.
  final List<List<pw.Widget>> _widgetStack = [];

  /// Inline span accumulator for current text block.
  List<pw.InlineSpan> _spans = [];

  /// Nested inline style tracking (bold, italic, code, etc.).
  final List<_StyleModifier> _styleStack = [];

  /// List nesting context stack.
  final List<_ListContext> _listStack = [];

  /// Current heading level (1-6), or null if not in a heading.
  int? _headingLevel;

  /// Table accumulation context, or null if not in a table.
  _TableContext? _tableCtx;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Convert [nodes] (from [md.Document.parse]) into PDF widgets.
  List<pw.Widget> render(List<md.Node> nodes) {
    _widgetStack
      ..clear()
      ..add([]);
    _spans = [];
    _styleStack.clear();
    _listStack.clear();
    _headingLevel = null;
    _tableCtx = null;

    for (final node in nodes) {
      node.accept(this);
    }
    _flushSpans();
    return _widgetStack.first;
  }

  // ── Widget helpers ─────────────────────────────────────────────────────

  List<pw.Widget> get _widgets => _widgetStack.last;
  void _addWidget(pw.Widget w) => _widgets.add(w);
  void _pushWidgets() => _widgetStack.add([]);
  List<pw.Widget> _popWidgets() => _widgetStack.removeLast();

  /// Flush accumulated inline [_spans] into a [pw.RichText] widget and
  /// add it to the current widget accumulator.
  void _flushSpans() {
    if (_spans.isEmpty) return;
    _addWidget(pw.RichText(
      text: pw.TextSpan(children: List.of(_spans)),
      softWrap: true,
      overflow: pw.TextOverflow.span,
    ));
    _spans = [];
  }

  // ── Style computation ──────────────────────────────────────────────────

  pw.TextStyle _computeStyle() {
    var isBold = false;
    var isItalic = false;
    var isStrikethrough = false;
    var isCode = false;
    var isLink = false;

    for (final mod in _styleStack) {
      switch (mod.type) {
        case _StyleType.bold:
          isBold = true;
        case _StyleType.italic:
          isItalic = true;
        case _StyleType.strikethrough:
          isStrikethrough = true;
        case _StyleType.code:
          isCode = true;
        case _StyleType.link:
          isLink = true;
      }
    }

    // Heading context overrides font size and forces bold.
    final fs = _headingLevel != null ? _headingSize(_headingLevel!) : fontSize;
    if (_headingLevel != null) isBold = true;

    if (isCode) {
      final codeFontSize = _headingLevel != null ? fs * 0.875 : fontSize * 0.875;
      return pw.TextStyle(
        fontNormal: monoFont,
        fontBold: monoBoldFont,
        fontSize: codeFontSize,
        fontWeight: isBold ? pw.FontWeight.bold : null,
        fontFallback: [symbolsFont, emojiFont],
        background: pw.BoxDecoration(color: PdfColor.fromHex('#e8e8e8')),
        decoration: _combineDecorations(isStrikethrough, isLink),
        decorationColor: isLink ? PdfColors.blue800 : null,
        color: isLink ? PdfColors.blue800 : null,
      );
    }

    return pw.TextStyle(
      fontNormal: pw.Font.helvetica(),
      fontBold: pw.Font.helveticaBold(),
      fontItalic: pw.Font.helveticaOblique(),
      fontBoldItalic: pw.Font.helveticaBoldOblique(),
      fontSize: fs,
      fontWeight: isBold ? pw.FontWeight.bold : null,
      fontStyle: isItalic ? pw.FontStyle.italic : null,
      decoration: _combineDecorations(isStrikethrough, isLink),
      decorationColor: isLink ? PdfColors.blue800 : null,
      color: isLink ? PdfColors.blue800 : null,
      fontFallback: [monoFont, symbolsFont, emojiFont],
    );
  }

  double _headingSize(int level) => switch (level) {
        1 => fontSize * 2.0,
        2 => fontSize * 1.5,
        3 => fontSize * 1.25,
        4 => fontSize * 1.125,
        5 => fontSize,
        _ => fontSize * 0.875,
      };

  pw.TextDecoration? _combineDecorations(bool strikethrough, bool underline) {
    if (!strikethrough && !underline) return null;
    if (strikethrough && underline) {
      return pw.TextDecoration.combine([
        pw.TextDecoration.lineThrough,
        pw.TextDecoration.underline,
      ]);
    }
    return strikethrough
        ? pw.TextDecoration.lineThrough
        : pw.TextDecoration.underline;
  }

  void _popStyle(_StyleType type) {
    for (var i = _styleStack.length - 1; i >= 0; i--) {
      if (_styleStack[i].type == type) {
        _styleStack.removeAt(i);
        return;
      }
    }
  }

  // ── Code block builder ─────────────────────────────────────────────────

  pw.Widget _buildCodeBlock(String code) {
    final codeFontSize = fontSize * 0.625;
    final codeStyle = pw.TextStyle(
      font: monoFont,
      fontSize: codeFontSize,
      fontFallback: [symbolsFont, emojiFont],
    );
    final bgColor = PdfColor.fromHex('#f0f0f0');
    const borderRadius = pw.BorderRadius.all(pw.Radius.circular(4));

    // Strip a single trailing newline (common in fenced code blocks).
    final trimmed = code.endsWith('\n')
        ? code.substring(0, code.length - 1)
        : code;
    final lines = trimmed.split('\n');

    // Split into chunks of 35 lines to avoid page overflow.
    const maxLines = 35;
    if (lines.length <= maxLines) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
          ),
          child: pw.Text(trimmed, style: codeStyle),
        ),
      );
    }

    final chunks = <pw.Widget>[];
    for (var i = 0; i < lines.length; i += maxLines) {
      final end = (i + maxLines).clamp(0, lines.length);
      chunks.add(pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
          ),
          child: pw.Text(
            lines.sublist(i, end).join('\n'),
            style: codeStyle,
          ),
        ),
      ));
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(children: chunks),
    );
  }

  // ── Table cell builder ─────────────────────────────────────────────────

  pw.Widget _buildTableCell({String? align}) {
    final textAlign = switch (align) {
      'center' => pw.TextAlign.center,
      'right' => pw.TextAlign.right,
      _ => pw.TextAlign.left,
    };

    if (_spans.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(''),
      );
    }

    final widget = pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.RichText(
        text: pw.TextSpan(children: List.of(_spans)),
        textAlign: textAlign,
        softWrap: true,
      ),
    );
    _spans = [];
    return widget;
  }

  // ── NodeVisitor ────────────────────────────────────────────────────────

  /// Strip Unicode variation selectors (U+FE0E text, U+FE0F emoji) that the
  /// pdf package cannot render — they show up as boxes. The base characters
  /// will still match the correct glyph in NotoColorEmoji.
  static final _variationSelectors = RegExp('[\uFE0E\uFE0F]');
  static final _htmlComments = RegExp(r'<!--.*?-->', dotAll: true);

  @override
  void visitText(md.Text text) {
    final cleaned = text.text
        .replaceAll(_variationSelectors, '')
        .replaceAll(_htmlComments, '');
    if (cleaned.isEmpty) return;
    _spans.add(pw.TextSpan(text: cleaned, style: _computeStyle()));
  }

  @override
  bool visitElementBefore(md.Element element) {
    final tag = element.tag;

    switch (tag) {
      // ── Block elements ──

      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        _flushSpans();
        _headingLevel = int.parse(tag.substring(1));
        return true;

      case 'p':
        _flushSpans();
        return true;

      case 'pre':
        _flushSpans();
        final code = element.textContent.replaceAll(_variationSelectors, '');
        _addWidget(_buildCodeBlock(code));
        return false;

      case 'blockquote':
        _flushSpans();
        _pushWidgets();
        return true;

      case 'ul':
        _flushSpans();
        _listStack.add(_ListContext(ordered: false));
        return true;

      case 'ol':
        _flushSpans();
        final start = int.tryParse(element.attributes['start'] ?? '') ?? 1;
        _listStack.add(_ListContext(ordered: true, counter: start));
        return true;

      case 'li':
        _flushSpans();
        _pushWidgets();
        return true;

      case 'hr':
        _flushSpans();
        _addWidget(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        ));
        return false;

      case 'table':
        _flushSpans();
        _tableCtx = _TableContext();
        return true;

      case 'thead':
        _tableCtx?.inHeader = true;
        return true;

      case 'tbody':
        _tableCtx?.inHeader = false;
        return true;

      case 'tr':
        _tableCtx?.startRow();
        return true;

      case 'th':
        _styleStack.add(_StyleModifier(_StyleType.bold));
        _spans = [];
        return true;

      case 'td':
        _spans = [];
        return true;

      // ── Inline elements ──

      case 'strong':
        _styleStack.add(_StyleModifier(_StyleType.bold));
        return true;

      case 'em':
        _styleStack.add(_StyleModifier(_StyleType.italic));
        return true;

      case 'del':
        _styleStack.add(_StyleModifier(_StyleType.strikethrough));
        return true;

      case 'code':
        _styleStack.add(_StyleModifier(_StyleType.code));
        return true;

      case 'a':
        _styleStack.add(
          _StyleModifier(_StyleType.link, href: element.attributes['href']),
        );
        return true;

      case 'br':
        _spans.add(pw.TextSpan(text: '\n', style: _computeStyle()));
        return false;

      case 'img':
        final src = element.attributes['src'] ?? '';
        final alt = element.attributes['alt'] ?? '';
        final image = images[src];
        if (image != null) {
          _flushSpans();
          _addWidget(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(maxHeight: 700),
              child: pw.Image(
                image,
                dpi: 300,
                fit: pw.BoxFit.scaleDown,
              ),
            ),
          ));
        } else if (alt.isNotEmpty) {
          _spans.add(pw.TextSpan(text: '[$alt]', style: _computeStyle()));
        }
        return false;

      case 'input':
        // GFM task list checkbox — uses Unicode ballot box glyphs from
        // Noto Sans Symbols 2 (☐ U+2610, ☑ U+2611).
        final checked = element.attributes.containsKey('checked');
        _spans.add(pw.TextSpan(
          text: '${checked ? '\u2611' : '\u2610'} ',
          style: pw.TextStyle(
            font: symbolsFont,
            fontSize: fontSize,
            fontFallback: [monoFont, emojiFont],
          ),
        ));
        return false;

      default:
        return true;
    }
  }

  @override
  void visitElementAfter(md.Element element) {
    final tag = element.tag;

    switch (tag) {
      // ── Block exits ──

      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        if (_spans.isNotEmpty) {
          final hs = _headingSize(_headingLevel!);
          _addWidget(pw.Padding(
            padding: pw.EdgeInsets.only(top: hs * 0.4, bottom: hs * 0.2),
            child: pw.RichText(
              text: pw.TextSpan(children: List.of(_spans)),
              softWrap: true,
              overflow: pw.TextOverflow.span,
            ),
          ));
          _spans = [];
        }
        _headingLevel = null;

      case 'p':
        if (_spans.isNotEmpty) {
          _addWidget(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.RichText(
              text: pw.TextSpan(children: List.of(_spans)),
              softWrap: true,
              overflow: pw.TextOverflow.span,
            ),
          ));
          _spans = [];
        }

      case 'blockquote':
        _flushSpans();
        final children = _popWidgets();
        _addWidget(pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.only(left: 12, top: 4, bottom: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: PdfColors.grey400, width: 3),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ));

      case 'ul' || 'ol':
        if (_listStack.isNotEmpty) _listStack.removeLast();

      case 'li':
        _flushSpans();
        final children = _popWidgets();
        final depth = (_listStack.length - 1).clamp(0, 5);
        final indent = depth * 20.0;

        if (_listStack.isNotEmpty) {
          final ctx = _listStack.last;
          final prefix = ctx.ordered ? '${ctx.counter}. ' : '\u2022 ';
          ctx.counter++;

          _addWidget(pw.Padding(
            padding: pw.EdgeInsets.only(left: 16 + indent, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: ctx.ordered ? 24 : 12,
                  child: pw.Text(
                    prefix,
                    style: pw.TextStyle(
                      fontNormal: pw.Font.helvetica(),
                      fontSize: fontSize,
                      fontFallback: [monoFont, symbolsFont, emojiFont],
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ],
            ),
          ));
        } else {
          // li outside a list context — add children directly.
          for (final c in children) {
            _addWidget(c);
          }
        }

      case 'th':
        _popStyle(_StyleType.bold);
        _tableCtx?.addCell(
          _buildTableCell(align: element.attributes['align']),
        );

      case 'td':
        _tableCtx?.addCell(
          _buildTableCell(align: element.attributes['align']),
        );

      case 'tr':
        _tableCtx?.finishRow();

      case 'thead':
        _tableCtx?.inHeader = false;

      case 'table':
        if (_tableCtx != null && _tableCtx!.rows.isNotEmpty) {
          _addWidget(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              defaultColumnWidth: const pw.IntrinsicColumnWidth(),
              children: _tableCtx!.rows,
            ),
          ));
        }
        _tableCtx = null;

      // ── Inline exits ──

      case 'strong':
        _popStyle(_StyleType.bold);
      case 'em':
        _popStyle(_StyleType.italic);
      case 'del':
        _popStyle(_StyleType.strikethrough);
      case 'code':
        _popStyle(_StyleType.code);
      case 'a':
        _popStyle(_StyleType.link);
    }
  }
}

// ── Internal types ─────────────────────────────────────────────────────────

enum _StyleType { bold, italic, strikethrough, code, link }

class _StyleModifier {
  final _StyleType type;
  final String? href;
  _StyleModifier(this.type, {this.href});
}

class _ListContext {
  final bool ordered;
  int counter;
  _ListContext({required this.ordered, this.counter = 1});
}

class _TableContext {
  bool inHeader = false;
  final List<pw.TableRow> rows = [];
  List<pw.Widget> _currentCells = [];

  void startRow() => _currentCells = [];

  void addCell(pw.Widget cell) => _currentCells.add(cell);

  void finishRow() {
    rows.add(pw.TableRow(
      decoration: inHeader
          ? pw.BoxDecoration(color: PdfColor.fromHex('#f0f0f0'))
          : null,
      repeat: inHeader,
      children: List.of(_currentCells),
    ));
  }
}
