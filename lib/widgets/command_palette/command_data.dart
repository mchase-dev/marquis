import 'dart:io';

import 'package:flutter/material.dart';

import 'package:marquis/models/command_item.dart';

/// Static command data for the command palette [DD §11]
class CommandData {
  CommandData._();

  /// All markdown snippet commands [DD §11 — Markdown Snippets table]
  static List<CommandItem> snippets() {
    return const [
      CommandItem(
        name: 'Heading 1',
        description: 'Insert level 1 heading',
        icon: Icons.looks_one_outlined,
        snippet: '# ',
        shortcut: 'Ctrl+1',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Heading 2',
        description: 'Insert level 2 heading',
        icon: Icons.looks_two_outlined,
        snippet: '## ',
        shortcut: 'Ctrl+2',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Heading 3',
        description: 'Insert level 3 heading',
        icon: Icons.looks_3_outlined,
        snippet: '### ',
        shortcut: 'Ctrl+3',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Heading 4',
        description: 'Insert level 4 heading',
        icon: Icons.looks_4_outlined,
        snippet: '#### ',
        shortcut: 'Ctrl+4',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Heading 5',
        description: 'Insert level 5 heading',
        icon: Icons.looks_5_outlined,
        snippet: '##### ',
        shortcut: 'Ctrl+5',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Heading 6',
        description: 'Insert level 6 heading',
        icon: Icons.looks_6_outlined,
        snippet: '###### ',
        shortcut: 'Ctrl+6',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Bold',
        description: 'Insert bold text',
        icon: Icons.format_bold,
        snippet: '**bold**',
        shortcut: 'Ctrl+B',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Italic',
        description: 'Insert italic text',
        icon: Icons.format_italic,
        snippet: '*italic*',
        shortcut: 'Ctrl+I',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Strikethrough',
        description: 'Insert strikethrough text',
        icon: Icons.format_strikethrough,
        snippet: '~~strikethrough~~',
        shortcut: 'Alt+S',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Inline Code',
        description: 'Insert inline code',
        icon: Icons.code,
        snippet: '`code`',
        shortcut: 'Ctrl+`',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Code Block',
        description: 'Insert fenced code block',
        icon: Icons.integration_instructions_outlined,
        snippet: '```language\n\n```',
        shortcut: 'Ctrl+Shift+K',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Link',
        description: 'Insert hyperlink',
        icon: Icons.link,
        snippet: '[text](url)',
        shortcut: 'Ctrl+K',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Image',
        description: 'Insert image',
        icon: Icons.image_outlined,
        snippet: '![alt](url)',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Unordered List',
        description: 'Insert bullet list item',
        icon: Icons.format_list_bulleted,
        snippet: '- item',
        shortcut: 'Ctrl+Shift+8',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Ordered List',
        description: 'Insert numbered list item',
        icon: Icons.format_list_numbered,
        snippet: '1. item',
        shortcut: 'Ctrl+Shift+9',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Task List',
        description: 'Insert task list item',
        icon: Icons.check_box_outlined,
        snippet: '- [ ] task',
        shortcut: 'Ctrl+Shift+X',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Block Quote',
        description: 'Insert block quote',
        icon: Icons.format_quote,
        snippet: '> quote',
        shortcut: 'Ctrl+Shift+.',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Table',
        description: 'Insert 2x2 table',
        icon: Icons.table_chart_outlined,
        snippet: '| Header 1 | Header 2 |\n| -------- | -------- |\n| Cell 1   | Cell 2   |\n| Cell 3   | Cell 4   |',
        category: CommandCategory.snippet,
      ),
      CommandItem(
        name: 'Horizontal Rule',
        description: 'Insert horizontal rule',
        icon: Icons.horizontal_rule,
        snippet: '---',
        shortcut: 'Ctrl+Shift+-',
        category: CommandCategory.snippet,
      ),
    ];
  }

  /// Build app commands with action callbacks [DD §11 — App Commands]
  static List<CommandItem> appCommands({
    required VoidCallback onNewFile,
    required VoidCallback onOpenFile,
    required VoidCallback onSave,
    required VoidCallback onSaveAs,
    required VoidCallback onCloseTab,
    required VoidCallback onToggleEditMode,
    required VoidCallback onFind,
    required VoidCallback onFindReplace,
    required VoidCallback onPreferences,
    required VoidCallback onToggleTheme,
    required VoidCallback onPrint,
    required VoidCallback onExportPdf,
    required VoidCallback onAbout,
  }) {
    return [
      CommandItem(
        name: 'New File',
        description: 'Create a new untitled file',
        icon: Icons.note_add_outlined,
        shortcut: 'Ctrl+N',
        category: CommandCategory.file,
        action: onNewFile,
      ),
      CommandItem(
        name: 'Open File',
        description: 'Open a file from disk',
        icon: Icons.folder_open_outlined,
        shortcut: 'Ctrl+O',
        category: CommandCategory.file,
        action: onOpenFile,
      ),
      CommandItem(
        name: 'Save',
        description: 'Save the current file',
        icon: Icons.save_outlined,
        shortcut: 'Ctrl+S',
        category: CommandCategory.file,
        action: onSave,
      ),
      CommandItem(
        name: 'Save As',
        description: 'Save the current file with a new name',
        icon: Icons.save_as_outlined,
        shortcut: 'Ctrl+Shift+S',
        category: CommandCategory.file,
        action: onSaveAs,
      ),
      CommandItem(
        name: 'Close Tab',
        description: 'Close the current tab',
        icon: Icons.close,
        shortcut: 'Ctrl+W',
        category: CommandCategory.file,
        action: onCloseTab,
      ),
      CommandItem(
        name: 'Toggle Edit Mode',
        description: 'Switch between viewer and editor',
        icon: Icons.edit_outlined,
        shortcut: 'Ctrl+E',
        category: CommandCategory.edit,
        action: onToggleEditMode,
      ),
      CommandItem(
        name: 'Find',
        description: 'Search in document',
        icon: Icons.search,
        shortcut: 'Ctrl+F',
        category: CommandCategory.search,
        action: onFind,
      ),
      CommandItem(
        name: 'Find & Replace',
        description: 'Search and replace in document',
        icon: Icons.find_replace,
        shortcut: 'Ctrl+H',
        category: CommandCategory.search,
        action: onFindReplace,
      ),
      CommandItem(
        name: 'Preferences',
        description: 'Open application preferences',
        icon: Icons.settings_outlined,
        shortcut: 'Ctrl+,',
        category: CommandCategory.edit,
        action: onPreferences,
      ),
      CommandItem(
        name: 'Toggle Theme',
        description: 'Switch between light and dark theme',
        icon: Icons.brightness_6_outlined,
        category: CommandCategory.view,
        action: onToggleTheme,
      ),
      CommandItem(
        name: Platform.isWindows ? 'View as PDF' : 'Print',
        description: Platform.isWindows
            ? 'View the current document as PDF'
            : 'Print the current document',
        icon: Platform.isWindows ? Icons.picture_as_pdf_outlined : Icons.print_outlined,
        shortcut: 'Ctrl+P',
        category: CommandCategory.file,
        action: onPrint,
      ),
      CommandItem(
        name: 'Export to PDF',
        description: 'Save the current document as a PDF file',
        icon: Icons.picture_as_pdf_outlined,
        category: CommandCategory.file,
        action: onExportPdf,
      ),
      CommandItem(
        name: 'About Marquis',
        description: 'About this application',
        icon: Icons.info_outlined,
        category: CommandCategory.help,
        action: onAbout,
      ),
    ];
  }

  /// Fuzzy match filter [DD §11 — Implementation Details]
  static bool matchesFilter(CommandItem item, String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    final lowerName = item.name.toLowerCase();
    final lowerDesc = item.description?.toLowerCase() ?? '';

    // Substring match on name or description
    if (lowerName.contains(lowerQuery)) return true;
    if (lowerDesc.contains(lowerQuery)) return true;

    // Token match: all query words must match somewhere
    final tokens = lowerQuery.split(RegExp(r'\s+'));
    final combined = '$lowerName $lowerDesc';
    return tokens.every((token) => combined.contains(token));
  }
}
