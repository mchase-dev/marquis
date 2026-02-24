# Marquis User Guide

Welcome to **Marquis**, a clean and focused Markdown editor for your desktop.

## Getting Started

### Opening Files

- **File > Open** (Ctrl+O): Browse for `.md` or `.markdown` files
- **Drag and drop**: Drop files onto the window to open them
- **Recent files**: Use File > Open Recent or the Welcome screen

### Creating Files

- **File > New** (Ctrl+N): Creates a new untitled document in edit mode
- Save with Ctrl+S — you'll be prompted to choose a location

### Saving Files

- **Save** (Ctrl+S): Save the current file (prompts for location if untitled)
- **Save As** (Ctrl+Shift+S): Save a copy with a new name or location

---

## The Editor

### View Modes

Marquis has three view modes, accessible from the View menu or toolbar:

| Mode | Description | Shortcut |
|------|-------------|----------|
| Viewer Only | Read and preview your Markdown | Default |
| Split View | Editor on the left, live preview on the right | Ctrl+E |
| Editor Only | Full-width editing | Ctrl+Shift+E |

### Live Preview

In Split View, the preview updates instantly as you type. The editor and viewer scroll together proportionally.

### Resizable Split

In Split View, drag the divider between panes to adjust the split. Double-click the divider to reset to 50/50.

---

## Formatting

### Toolbar

When the editor is visible, a formatting toolbar appears with buttons for common Markdown syntax: bold, italic, headings, lists, links, and more.

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Bold | Ctrl+B |
| Italic | Ctrl+I |
| Strikethrough | Alt+S |
| Inline Code | Ctrl+` |
| Link | Ctrl+K |
| Heading 1–6 | Ctrl+1 through Ctrl+6 |
| Unordered List | Ctrl+Shift+8 |
| Ordered List | Ctrl+Shift+9 |
| Task List | Ctrl+Shift+X |
| Block Quote | Ctrl+Shift+. |
| Code Block | Ctrl+Shift+K |
| Horizontal Rule | Ctrl+Shift+- |

---

## Command Palette

Press **Ctrl+/** to open the Command Palette. Type to search for any command or Markdown snippet. Use arrow keys to navigate and Enter to execute.

---

## Tabs

- Open multiple files in tabs
- Drag tabs to reorder them
- Middle-click a tab to close it
- Right-click a tab for options: Close Others, Close All, Close to Right, Copy Path, Reveal in Explorer
- Switch tabs: Ctrl+Tab (next), Ctrl+Shift+Tab (previous)
- Jump to tab: Alt+1 through Alt+9

A dot (●) next to the filename indicates unsaved changes.

---

## Preferences

Open **File > Preferences** (Ctrl+,) to customize:

- **Theme**: Light, Dark, or follow System
- **Accent Color**: Choose from presets or pick a custom color
- **Font sizes**: Adjust editor and viewer font sizes independently
- **Editor font**: Choose from available monospace fonts
- **Word wrap, line numbers, tab size**: Fine-tune the editor
- **Auto-save**: Toggle on/off and set the delay (1–30 seconds)

Preferences are stored as an editable JSON file.

---

## Printing

Use **File > Print** (Ctrl+P) to print the current document. The Markdown is converted to a formatted PDF and sent to your system's print dialog.

---

## Keyboard Shortcuts Reference

### Global

| Action | Windows/Linux | macOS |
|--------|--------------|-------|
| New File | Ctrl+N | Cmd+N |
| Open File | Ctrl+O | Cmd+O |
| Save | Ctrl+S | Cmd+S |
| Save As | Ctrl+Shift+S | Cmd+Shift+S |
| Close Tab | Ctrl+W | Cmd+W |
| Rename | F2 | F2 |
| Print | Ctrl+P | Cmd+P |
| Quit | Ctrl+Q | Cmd+Q |
| Preferences | Ctrl+, | Cmd+, |
| Command Palette | Ctrl+/ | Cmd+/ |
| Toggle Edit Mode | Ctrl+E | Cmd+E |
| Editor Only | Ctrl+Shift+E | Cmd+Shift+E |
| Find | Ctrl+F | Cmd+F |
| Find & Replace | Ctrl+H | Cmd+Opt+F |
| Zoom In | Ctrl+= | Cmd+= |
| Zoom Out | Ctrl+- | Cmd+- |
| Reset Zoom | Ctrl+0 | Cmd+0 |
| Full Screen | F11 | Ctrl+Cmd+F |
| Next Tab | Ctrl+Tab | Ctrl+Tab |
| Previous Tab | Ctrl+Shift+Tab | Ctrl+Shift+Tab |
| Go to Tab 1–9 | Alt+1–Alt+9 | — |
