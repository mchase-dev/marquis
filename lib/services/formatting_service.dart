import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

/// Markdown formatting operations for the editor [DD §8 — Markdown Formatting Shortcuts]
class FormattingService {
  FormattingService._();

  /// Wrap selected text or insert markers at cursor [DD §8 — Selection wrapping]
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

  /// Insert prefix at the beginning of the current line [DD §8 — Line-start insertion]
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

  // --- Specific formatting actions [DD §8 — Shortcuts table] ---

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
}
