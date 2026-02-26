import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';
import 'package:markdown/markdown.dart' show ExtensionSet;
import 'package:printing/printing.dart';

/// Converts Markdown to PDF and opens the native print dialog [DD §18].
class PrintService {
  PrintService._();

  static Future<void> printDocument({
    required String content,
    required String documentName,
    String? filePath,
    double fontSize = 16,
  }) async {
    final widgets = await HTMLToPdf().convertMarkdown(
      content,
      defaultFontSize: fontSize,
      extensionSet: ExtensionSet.gitHubFlavored,
    );

    final pdf = Document();
    pdf.addPage(MultiPage(
      maxPages: 200,
      build: (context) => widgets,
    ));

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: documentName,
    );
  }
}
