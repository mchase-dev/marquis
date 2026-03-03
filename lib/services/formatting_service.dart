import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

/// Markdown formatting operations for the editor
class FormattingService {
  FormattingService._();

  /// Wrap selected text or insert markers at cursor
  static void wrapSelection(
    CodeLineEditingController controller,
    String before,
    String after,
  ) {
    controller.runRevocableOp(() {
      final selected = controller.selectedText;
      if (selected.isNotEmpty) {
        controller.replaceSelection('$before$selected$after');
      } else {
        controller.replaceSelection('$before$after');
        for (int i = 0; i < after.length; i++) {
          controller.moveCursor(AxisDirection.left);
        }
      }
    });
  }

  /// Insert prefix at the beginning of the current line
  static void insertLinePrefix(
    CodeLineEditingController controller,
    String prefix,
  ) {
    controller.runRevocableOp(() {
      final sel = controller.selection;
      final lineIndex = sel.baseIndex;
      final line = controller.codeLines[lineIndex];
      final lineText = line.text;

      // Remove existing heading prefixes if inserting a heading
      String newText;
      if (prefix.startsWith('#')) {
        // Strip existing heading prefix
        final stripped = lineText.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
        newText = '$prefix$stripped';
      } else {
        newText = '$prefix$lineText';
      }

      // Select the entire line and replace it
      controller.selection = CodeLineSelection(
        baseIndex: lineIndex,
        baseOffset: 0,
        extentIndex: lineIndex,
        extentOffset: lineText.length,
      );
      controller.replaceSelection(newText);
    });
  }

  // --- Specific formatting actions ---

  static void bold(CodeLineEditingController c) =>
      wrapSelection(c, '**', '**');

  static void italic(CodeLineEditingController c) =>
      wrapSelection(c, '*', '*');

  static void strikethrough(CodeLineEditingController c) =>
      wrapSelection(c, '~~', '~~');

  static void inlineCode(CodeLineEditingController c) =>
      wrapSelection(c, '`', '`');

  static void link(CodeLineEditingController c) {
    c.runRevocableOp(() {
      final selected = c.selectedText;
      if (selected.isNotEmpty) {
        c.replaceSelection('[$selected](url)');
      } else {
        c.replaceSelection('[text](url)');
        // Select "text" so user can type over it
        for (int i = 0; i < '](url)'.length; i++) {
          c.moveCursor(AxisDirection.left);
        }
        for (int i = 0; i < 'text'.length; i++) {
          c.moveCursor(AxisDirection.left);
        }
        for (int i = 0; i < 'text'.length; i++) {
          c.extendSelection(AxisDirection.right);
        }
      }
    });
  }

  static void image(CodeLineEditingController c) {
    c.runRevocableOp(() {
      final selected = c.selectedText;
      if (selected.isNotEmpty) {
        c.replaceSelection('![$selected](url)');
      } else {
        c.replaceSelection('![alt](url)');
        for (int i = 0; i < '](url)'.length; i++) {
          c.moveCursor(AxisDirection.left);
        }
        for (int i = 0; i < 'alt'.length; i++) {
          c.moveCursor(AxisDirection.left);
        }
        for (int i = 0; i < 'alt'.length; i++) {
          c.extendSelection(AxisDirection.right);
        }
      }
    });
  }

  static void heading(CodeLineEditingController c, int level) {
    final prefix = '${'#' * level} ';
    insertLinePrefix(c, prefix);
  }

  static void unorderedList(CodeLineEditingController c) =>
      insertLinePrefix(c, '- ');

  static void orderedList(CodeLineEditingController c) =>
      insertLinePrefix(c, '1. ');

  static void taskList(CodeLineEditingController c) =>
      insertLinePrefix(c, '- [ ] ');

  static void blockQuote(CodeLineEditingController c) =>
      insertLinePrefix(c, '> ');

  static void codeBlock(CodeLineEditingController c) {
    c.runRevocableOp(() {
      final selected = c.selectedText;
      if (selected.isNotEmpty) {
        c.replaceSelection('```\n$selected\n```');
      } else {
        c.replaceSelection('```\n\n```');
        c.moveCursor(AxisDirection.up);
      }
    });
  }

  static void horizontalRule(CodeLineEditingController c) {
    c.runRevocableOp(() {
      c.replaceSelection('\n---\n');
    });
  }

  static void table(CodeLineEditingController c) {
    c.runRevocableOp(() {
      c.replaceSelection('| Header | Header |\n| ------ | ------ |\n| Cell   | Cell   |');
    });
  }

  // --- List continuation on Enter ---

  static final _unorderedRe =
      RegExp(r'^(\s*)([*+-])\s+(?:(\[[ xX]\])\s+)?(.*)$');
  static final _orderedRe = RegExp(r'^(\s*)(\d+)\.\s+(.*)$');

  /// Analyze a line to determine list continuation behavior.
  ///
  /// Returns `null` if the line is not a list line.
  /// Returns `exit: true` if the list item content is empty (should exit list).
  /// Returns `exit: false` with the continuation prefix otherwise.
  static ({String prefix, bool exit})? analyzeListLine(String lineText) {
    final unordered = _unorderedRe.firstMatch(lineText);
    if (unordered != null) {
      final indent = unordered.group(1)!;
      final marker = unordered.group(2)!;
      final checkbox = unordered.group(3);
      final content = unordered.group(4)!;

      if (content.trim().isEmpty) {
        return (prefix: '', exit: true);
      }
      final prefix = checkbox != null
          ? '$indent$marker [ ] '
          : '$indent$marker ';
      return (prefix: prefix, exit: false);
    }

    final ordered = _orderedRe.firstMatch(lineText);
    if (ordered != null) {
      final indent = ordered.group(1)!;
      final number = int.parse(ordered.group(2)!);
      final content = ordered.group(3)!;

      if (content.trim().isEmpty) {
        return (prefix: '', exit: true);
      }
      return (prefix: '$indent${number + 1}. ', exit: false);
    }

    return null;
  }

  /// Apply list continuation after re_editor has already inserted a newline.
  ///
  /// For continuation: inserts the list prefix at the start of the new line.
  /// For exit: removes the empty list marker and the extra newline.
  static void applyListContinuationAfterNewline(
    CodeLineEditingController controller, {
    required int originalLineIndex,
    required String prefix,
    required bool exit,
  }) {
    controller.runRevocableOp(() {
      if (exit) {
        // re_editor added a newline after the empty list marker.
        // Line [originalLineIndex]: "- " (empty marker)
        // Line [originalLineIndex + 1]: "" (new empty line, cursor here)
        // Select from start of marker line to start of new line → collapse.
        controller.selection = CodeLineSelection(
          baseIndex: originalLineIndex,
          baseOffset: 0,
          extentIndex: originalLineIndex + 1,
          extentOffset: 0,
        );
        controller.replaceSelection('');
      } else {
        // re_editor split the line at the cursor. Insert prefix on new line.
        controller.selection = CodeLineSelection(
          baseIndex: originalLineIndex + 1,
          baseOffset: 0,
          extentIndex: originalLineIndex + 1,
          extentOffset: 0,
        );
        controller.replaceSelection(prefix);
      }
    });
  }
}
