import 'package:flutter/widgets.dart';

/// Represents a command in the command palette
class CommandItem {
  final String name;
  final String? description;
  final IconData? icon;
  final String? snippet;
  final String? shortcut;
  final CommandCategory category;
  final void Function()? action;

  const CommandItem({
    required this.name,
    this.description,
    this.icon,
    this.snippet,
    this.shortcut,
    this.category = CommandCategory.snippet,
    this.action,
  });

  /// Whether this is a snippet insertion command
  bool get isSnippet => snippet != null;

  /// Whether this is an app command (not a snippet)
  bool get isAppCommand => action != null;
}

/// Categories for grouping commands in the palette
enum CommandCategory {
  snippet,
  file,
  edit,
  view,
  search,
  help,
}
