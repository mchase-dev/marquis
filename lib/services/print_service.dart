import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'markdown_pdf_renderer.dart';

/// Converts Markdown to PDF for printing and export.
class PrintService {
  PrintService._();

  // -------------------------------------------------------------------------
  // Print
  // -------------------------------------------------------------------------

  static Future<void> printDocument({
    required String content,
    required String documentName,
    String? filePath,
    double fontSize = 16,
  }) async {
    final pdf = await _buildPdf(content, fontSize, filePath: filePath);
    final pdfBytes = await pdf.save();

    if (Platform.isWindows) {
      // Printing.layoutPdf freezes the app on Windows (native modal dialog
      // blocks Flutter's event loop). Instead, write a temp PDF and open it
      // in the default viewer where the user can print with Ctrl+P.
      final tempDir = await Directory.systemTemp.createTemp('marquis_print_');
      final safeName =
          documentName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final tempFile = File(p.join(tempDir.path, '$safeName.pdf'));
      await tempFile.writeAsBytes(pdfBytes);
      await Process.start('cmd', ['/c', 'start', '', tempFile.path]);
    } else {
      await Printing.layoutPdf(
        onLayout: (_) => Future.value(pdfBytes),
        name: documentName,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Export to PDF
  // -------------------------------------------------------------------------

  /// Export the document as a PDF file. Shows a Save As dialog and writes
  /// the PDF to the chosen location.
  static Future<void> exportToPdf({
    required String content,
    required String documentName,
    String? filePath,
    double fontSize = 16,
  }) async {
    // Suggest a .pdf filename based on the document name
    final baseName = p.basenameWithoutExtension(documentName);
    final suggestedName = '$baseName.pdf';

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export to PDF',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (outputPath == null) return;

    final pdf = await _buildPdf(content, fontSize, filePath: filePath);
    final pdfBytes = await pdf.save();
    await File(outputPath).writeAsBytes(pdfBytes);
  }

  // -------------------------------------------------------------------------
  // PDF generation (shared)
  // -------------------------------------------------------------------------

  static Future<Document> _buildPdf(
    String content,
    double fontSize, {
    String? filePath,
  }) async {
    final monoFont = Font.ttf(
      await rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'),
    );
    final monoBoldFont = Font.ttf(
      await rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'),
    );
    final symbolsFont = Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansSymbols2-Regular.ttf'),
    );
    final emojiFont = Font.ttf(
      await rootBundle.load('assets/fonts/NotoColorEmoji.ttf'),
    );

    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    ).parse(content);

    final images = await _loadImages(nodes, filePath);

    final renderer = MarkdownPdfRenderer(
      monoFont: monoFont,
      monoBoldFont: monoBoldFont,
      symbolsFont: symbolsFont,
      emojiFont: emojiFont,
      fontSize: fontSize,
      images: images,
    );

    final widgets = renderer.render(nodes);

    final pdf = Document(
      theme: ThemeData.withFont(fontFallback: [monoFont, symbolsFont, emojiFont]),
    );
    pdf.addPage(MultiPage(maxPages: 200, build: (context) => widgets));
    return pdf;
  }

  // -------------------------------------------------------------------------
  // Image loading
  // -------------------------------------------------------------------------

  /// Recursively collect all image `src` attributes from the parsed AST.
  static Set<String> _collectImageSources(List<md.Node> nodes) {
    final sources = <String>{};
    for (final node in nodes) {
      if (node is md.Element) {
        if (node.tag == 'img') {
          final src = node.attributes['src'];
          if (src != null && src.isNotEmpty) sources.add(src);
        }
        if (node.children != null) {
          sources.addAll(_collectImageSources(node.children!));
        }
      }
    }
    return sources;
  }

  /// Resolve an image [src] to raw bytes.
  ///
  /// Handles `file://` URIs, `http(s)://` URLs, absolute file paths, and
  /// paths relative to [documentDir] (the directory containing the markdown
  /// file). Returns `null` on any failure.
  static Future<Uint8List?> _loadImageBytes(
    String src, {
    String? documentDir,
  }) async {
    try {
      // file:// URI
      if (src.startsWith('file://')) {
        final file = File(Uri.parse(src).toFilePath());
        if (await file.exists()) return file.readAsBytes();
        return null;
      }

      // HTTP(S) URL
      if (src.startsWith('http://') || src.startsWith('https://')) {
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse(src))
            ..followRedirects = true;
          final response =
              await request.close().timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            final chunks = await response.toList();
            final bytes = BytesBuilder();
            for (final chunk in chunks) {
              bytes.add(chunk);
            }
            return bytes.toBytes();
          }
        } finally {
          client.close();
        }
        return null;
      }

      // Absolute file path
      if (p.isAbsolute(src)) {
        final file = File(src);
        if (await file.exists()) return file.readAsBytes();
        return null;
      }

      // Relative path — resolve against document directory
      if (documentDir != null) {
        final file = File(p.join(documentDir, src));
        if (await file.exists()) return file.readAsBytes();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Pre-load all images referenced in the AST. Returns a map from `src`
  /// attribute to [pw.MemoryImage] for successfully loaded images.
  static Future<Map<String, pw.MemoryImage>> _loadImages(
    List<md.Node> nodes,
    String? filePath,
  ) async {
    final sources = _collectImageSources(nodes);
    if (sources.isEmpty) return const {};

    final documentDir = filePath != null ? p.dirname(filePath) : null;
    final images = <String, pw.MemoryImage>{};

    for (final src in sources) {
      final bytes = await _loadImageBytes(src, documentDir: documentDir);
      if (bytes != null) {
        try {
          images[src] = pw.MemoryImage(bytes);
        } catch (_) {
          // Invalid image data — skip, will fall back to alt text.
        }
      }
    }
    return images;
  }
}
