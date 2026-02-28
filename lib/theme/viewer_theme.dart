import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:markdown_widget/markdown_widget.dart';

/// Viewer-specific MarkdownConfig for light and dark modes
class ViewerTheme {
  ViewerTheme._();

  /// Build a light-mode MarkdownConfig with the given viewer font size
  static MarkdownConfig light({double fontSize = 16}) {
    return MarkdownConfig(configs: [
      PConfig(textStyle: TextStyle(fontSize: fontSize)),
      PreConfig(
        theme: githubTheme,
        textStyle: TextStyle(fontSize: fontSize - 2, fontFamily: 'JetBrains Mono'),
        styleNotMatched: const TextStyle(),
        decoration: const BoxDecoration(
          color: Color(0xFFF6F8FA),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    ]);
  }

  /// Build a dark-mode MarkdownConfig with the given viewer font size
  static MarkdownConfig dark({double fontSize = 16}) {
    return MarkdownConfig.darkConfig.copy(configs: [
      PConfig(
        textStyle: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFFD4D4D4),
        ),
      ),
      PreConfig(
        theme: monokaiSublimeTheme,
        textStyle: TextStyle(fontSize: fontSize - 2, fontFamily: 'JetBrains Mono'),
        styleNotMatched: const TextStyle(),
        decoration: const BoxDecoration(
          color: Color(0xFF272822),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    ]);
  }
}
