# NootSpace Implementation Plan

**Version:** 1.0
**Date:** 2025-12-17
**Project:** NootSpace - Cross-Platform Knowledge Management Application

---

## 1. Executive Summary

NootSpace is a cross-platform knowledge management and productivity application built with Flutter. This document outlines the implementation strategy for developing the MVP and subsequent phases, following Flutter best practices and clean architecture principles.

### Goals

- Deliver a functional MVP with core note-taking, block editing, internal linking, and search capabilities
- Ensure cross-platform compatibility (Windows, macOS, Linux, iOS, Android)
- Build a maintainable, scalable codebase using layered architecture
- Implement offline-first functionality with local SQLite storage

---

## 2. Technology Stack

### Core Framework

| Technology | Purpose                     | Version             |
| ---------- | --------------------------- | ------------------- |
| Flutter    | Cross-platform UI framework | 3.x (latest stable) |
| Dart       | Programming language        | 3.x (latest stable) |

### State Management & Architecture

| Package             | Purpose                       |
| ------------------- | ----------------------------- |
| flutter_riverpod    | Reactive state management     |
| riverpod_annotation | Code generation for providers |
| build_runner        | Code generation tool          |
| freezed             | Immutable data classes        |
| freezed_annotation  | Freezed annotations           |
| json_serializable   | JSON serialization            |

### Data & Storage

| Package              | Purpose                    |
| -------------------- | -------------------------- |
| sqflite              | SQLite database for mobile |
| sqlite3_flutter_libs | SQLite for desktop         |
| drift                | Type-safe SQLite ORM       |
| path_provider        | File system paths          |
| shared_preferences   | Simple key-value storage   |

### UI & Editor

| Package          | Purpose                                    |
| ---------------- | ------------------------------------------ |
| super_editor     | Block-based editor (primary editor)        |
| flutter_markdown | Markdown rendering (for preview mode)      |
| markdown         | Markdown parsing                           |
| front_matter     | Parse YAML frontmatter from Markdown files |

### Graph Visualization

| Package                      | Purpose                     |
| ---------------------------- | --------------------------- |
| graphview                    | Graph/node visualization    |
| flutter_force_directed_graph | Force-directed graph layout |

### Icons

| Package                | Purpose                               |
| ---------------------- | ------------------------------------- |
| lucide_icons           | UI icons (toolbar, sidebar, buttons)  |
| flutter_launcher_icons | App icon generation for all platforms |

### Navigation

| Package   | Purpose                            |
| --------- | ---------------------------------- |
| go_router | Declarative routing and navigation |

### File System

| Package            | Purpose                          |
| ------------------ | -------------------------------- |
| watcher            | File system change detection     |
| file_picker        | Select images/files for import   |
| permission_handler | File system permissions (mobile) |

### Utilities

| Package           | Purpose                 |
| ----------------- | ----------------------- |
| uuid              | Unique ID generation    |
| intl              | Internationalization    |
| logger            | Logging utility         |
| collection        | Collection utilities    |
| package_info_plus | App version information |

### Testing

| Package          | Purpose             |
| ---------------- | ------------------- |
| flutter_test     | Widget testing      |
| mockito          | Mocking framework   |
| integration_test | Integration testing |

---

## 3. Architecture Design

### 3.1 Layered Architecture

NootSpace follows a **clean layered architecture** pattern:

```
┌─────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                │
│  (Widgets, Pages, Controllers, UI State)            │
├─────────────────────────────────────────────────────┤
│                   APPLICATION LAYER                 │
│  (Use Cases, Application Services, Providers)       │
├─────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                    │
│  (Entities, Repositories Interfaces, Value Objects) │
├─────────────────────────────────────────────────────┤
│                      DATA LAYER                     │
│  (Repository Implementations, Data Sources, DTOs)   │
└─────────────────────────────────────────────────────┘
```

### 3.2 Layer Responsibilities

**Presentation Layer**

- Flutter widgets and pages
- UI state management with Riverpod
- User interaction handling
- Navigation and routing

**Application Layer**

- Use cases orchestrating business operations
- Application-level providers
- Input validation and transformation

**Domain Layer**

- Core business entities (Noot, Nootspace, Block, Tag)
- Repository interfaces (contracts)
- Value objects and domain logic

**Data Layer**

- Repository implementations
- Local data sources (SQLite via Drift)
- File system operations for Markdown export
- Data Transfer Objects (DTOs)

### 3.3 State Management Pattern

Using Riverpod with the following provider types:

```dart
// Synchronous computed values
@riverpod
List<Noot> filteredNoots(FilteredNootsRef ref) { ... }

// Async data fetching
@riverpod
Future<Nootspace> nootspace(NootspaceRef ref, String id) { ... }

// Mutable state with business logic
@riverpod
class NootEditor extends _$NootEditor { ... }

// Stream-based reactive data
@riverpod
Stream<List<Noot>> nootsStream(NootsStreamRef ref) { ... }
```

---

## 4. Project Structure

```
nootspace/
├── android/                    # Android platform files
├── ios/                        # iOS platform files
├── linux/                      # Linux platform files
├── macos/                      # macOS platform files
├── windows/                    # Windows platform files
├── lib/
│   ├── main.dart               # Application entry point
│   ├── app.dart                # App widget and configuration
│   │
│   ├── l10n/                   # Localization
│   │   ├── app_en.arb          # English strings
│   │   └── app_localizations.dart
│   │
│   ├── core/                   # Core utilities and shared code
│   │   ├── constants/          # App-wide constants
│   │   │   ├── app_constants.dart
│   │   │   └── ui_constants.dart
│   │   ├── errors/             # Error handling
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── extensions/         # Dart/Flutter extensions
│   │   ├── theme/              # App theming
│   │   │   ├── app_colors.dart   # Centralized color definitions
│   │   │   ├── app_theme.dart
│   │   │   ├── dark_theme.dart
│   │   │   └── light_theme.dart
│   │   ├── utils/              # Utility functions
│   │   │   ├── debouncer.dart
│   │   │   └── string_utils.dart
│   │   ├── router/             # Navigation/routing
│   │   │   └── app_router.dart
│   │   └── services/           # Core services
│   │       ├── file_watcher_service.dart
│   │       ├── config_service.dart
│   │       └── markdown_file_service.dart
│   │
│   ├── data/                   # Data layer
│   │   ├── datasources/        # Data source implementations
│   │   │   ├── local/
│   │   │   │   ├── database/
│   │   │   │   │   ├── app_database.dart
│   │   │   │   │   ├── tables/
│   │   │   │   │   └── daos/
│   │   │   │   └── file_storage.dart
│   │   │   └── dto/            # Data Transfer Objects
│   │   │       ├── noot_dto.dart
│   │   │       ├── nootspace_dto.dart
│   │   │       └── block_dto.dart
│   │   └── repositories/       # Repository implementations
│   │       ├── noot_repository_impl.dart
│   │       ├── nootspace_repository_impl.dart
│   │       └── search_repository_impl.dart
│   │
│   ├── domain/                 # Domain layer
│   │   ├── entities/           # Business entities
│   │   │   ├── noot.dart
│   │   │   ├── nootspace.dart
│   │   │   ├── block.dart
│   │   │   ├── tag.dart
│   │   │   └── link.dart
│   │   ├── repositories/       # Repository interfaces
│   │   │   ├── noot_repository.dart
│   │   │   ├── nootspace_repository.dart
│   │   │   └── search_repository.dart
│   │   └── value_objects/      # Value objects
│   │       ├── noot_id.dart
│   │       └── nootspace_id.dart
│   │
│   ├── application/            # Application layer
│   │   ├── providers/          # Riverpod providers
│   │   │   ├── noot_providers.dart
│   │   │   ├── nootspace_providers.dart
│   │   │   ├── editor_providers.dart
│   │   │   ├── search_providers.dart
│   │   │   └── theme_providers.dart
│   │   └── services/           # Application services
│   │       ├── markdown_service.dart
│   │       ├── link_parser_service.dart
│   │       └── search_service.dart
│   │
│   └── presentation/           # Presentation layer
│       ├── widgets/            # Reusable widgets
│       │   ├── common/
│       │   │   ├── app_scaffold.dart
│       │   │   ├── loading_indicator.dart
│       │   │   └── error_view.dart
│       │   ├── editor/
│       │   │   ├── block_editor.dart
│       │   │   ├── block_widget.dart
│       │   │   ├── text_block.dart
│       │   │   ├── heading_block.dart
│       │   │   ├── checklist_block.dart
│       │   │   ├── image_block.dart
│       │   │   └── table_block.dart
│       │   ├── navigation/
│       │   │   ├── sidebar.dart
│       │   │   ├── noot_tree.dart
│       │   │   └── breadcrumb.dart
│       │   └── graph/
│       │       ├── graph_view.dart
│       │       └── node_widget.dart
│       │
│       └── pages/              # App screens/pages
│           ├── home/
│           │   ├── home_page.dart
│           │   └── home_controller.dart
│           ├── editor/
│           │   ├── editor_page.dart
│           │   └── editor_controller.dart
│           ├── nootspace/
│           │   ├── nootspace_page.dart
│           │   └── nootspace_controller.dart
│           ├── search/
│           │   ├── search_page.dart
│           │   └── search_controller.dart
│           ├── graph/
│           │   ├── graph_page.dart
│           │   └── graph_controller.dart
│           └── settings/
│               ├── settings_page.dart
│               └── settings_controller.dart
│
├── test/                       # Unit and widget tests
│   ├── domain/
│   ├── data/
│   ├── application/
│   └── presentation/
│
├── integration_test/           # Integration tests
│
├── assets/                     # Static assets
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── pubspec.yaml                # Dependencies
├── analysis_options.yaml       # Linter rules
└── README.md                   # Project documentation
```

---

## 5. Branding & Theming

### 5.1 Brand Colors

All brand colors are centralized in `lib/core/theme/app_colors.dart` for easy modification.

| Color Name           | Hex Value | Usage                                          |
| -------------------- | --------- | ---------------------------------------------- |
| Primary Purple       | `#8B5CF6` | Primary accent, buttons, links, gradient start |
| Primary Cyan         | `#06B6D4` | Secondary accent, highlights, gradient end     |
| Dark Slate           | `#1E293B` | Text on light theme, dark theme background     |
| Light Background     | `#FFFFFF` | Light theme background                         |
| Dark Background      | `#0F172A` | Dark theme background                          |
| Surface Light        | `#F8FAFC` | Cards, panels on light theme                   |
| Surface Dark         | `#1E293B` | Cards, panels on dark theme                    |
| Text Primary Light   | `#1E293B` | Primary text on light theme                    |
| Text Primary Dark    | `#F1F5F9` | Primary text on dark theme                     |
| Text Secondary Light | `#64748B` | Secondary/muted text on light                  |
| Text Secondary Dark  | `#94A3B8` | Secondary/muted text on dark                   |

### 5.2 Color Implementation

Colors are defined in a single file for easy modification:

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Centralized color definitions for NootSpace.
///
/// To change the app's color scheme, modify the values here.
/// All theme files reference these colors, so changes propagate automatically.
abstract class AppColors {
  // ===========================================
  // BRAND COLORS - Modify these to rebrand
  // ===========================================

  /// Primary brand color (purple from logo)
  static const Color primaryPurple = Color(0xFF8B5CF6);

  /// Secondary brand color (cyan from logo)
  static const Color primaryCyan = Color(0xFF06B6D4);

  /// Brand gradient (used in logo and accents)
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryPurple, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================
  // SEMANTIC COLORS - Derived from brand
  // ===========================================

  /// Primary color used for buttons, links, focus states
  static const Color primary = primaryPurple;

  /// Secondary/accent color
  static const Color secondary = primaryCyan;

  // ===========================================
  // LIGHT THEME COLORS
  // ===========================================

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ===========================================
  // DARK THEME COLORS
  // ===========================================

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ===========================================
  // STATUS COLORS
  // ===========================================

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
```

### 5.3 Logo Assets

Logo files are located in `assets/images/` (copied from `logos/` folder):

| File                                 | Usage                         |
| ------------------------------------ | ----------------------------- |
| `nootspace-logo.png`                  | Light theme, splash screen    |
| `nootspace-logo-dark.png`             | Dark theme                    |
| `nootspace-logo-transparent.png`      | Overlays on light backgrounds |
| `nootspace-logo-dark-transparent.png` | Overlays on dark backgrounds  |

### 5.4 Changing Colors Later

To modify the color scheme:

1. **Quick rebrand**: Edit only the "BRAND COLORS" section in `app_colors.dart`
2. **Full theme change**: Modify both brand and semantic colors
3. **Add new colors**: Add new static constants and reference them in theme files

The theme files (`app_theme.dart`, `dark_theme.dart`, `light_theme.dart`) reference `AppColors` exclusively, so all changes propagate automatically.

### 5.5 Typography

**Font Families:**

| Usage            | Font           | Fallback              |
| ---------------- | -------------- | --------------------- |
| UI / Headings    | Inter          | system-ui, sans-serif |
| Body text        | Inter          | system-ui, sans-serif |
| Code / Monospace | JetBrains Mono | monospace             |

**Type Scale:**

| Style      | Size | Weight         | Line Height | Usage                    |
| ---------- | ---- | -------------- | ----------- | ------------------------ |
| Display    | 36px | Bold (700)     | 1.2         | Splash, empty states     |
| H1         | 32px | Bold (700)     | 1.25        | Page titles              |
| H2         | 24px | SemiBold (600) | 1.3         | Section headers          |
| H3         | 20px | SemiBold (600) | 1.4         | Subsections              |
| H4         | 18px | Medium (500)   | 1.4         | Minor headings           |
| Body       | 16px | Regular (400)  | 1.6         | Main content             |
| Body Small | 14px | Regular (400)  | 1.5         | Secondary content        |
| Caption    | 12px | Regular (400)  | 1.4         | Labels, metadata         |
| Code       | 14px | Regular (400)  | 1.5         | Code blocks, inline code |

**Spacing Constants:**

| Name          | Value | Usage            |
| ------------- | ----- | ---------------- |
| `spacing.xs`  | 4px   | Tight gaps       |
| `spacing.sm`  | 8px   | Related items    |
| `spacing.md`  | 16px  | Standard padding |
| `spacing.lg`  | 24px  | Section gaps     |
| `spacing.xl`  | 32px  | Major sections   |
| `spacing.xxl` | 48px  | Page margins     |

### 5.6 Icons

**UI Icons: Lucide**

All UI icons use the [Lucide](https://lucide.dev/icons/) icon library for a clean, consistent look.

```dart
import 'package:lucide_icons/lucide_icons.dart';

// Example usage
Icon(LucideIcons.file)
Icon(LucideIcons.folder)
Icon(LucideIcons.search)
```

**Common icons reference:**

| Purpose      | Icon  | Lucide Name             |
| ------------ | ----- | ----------------------- |
| New noot     | 📄    | `filePlus`              |
| Folder       | 📁    | `folder`                |
| Open folder  | 📂    | `folderOpen`            |
| Search       | 🔍    | `search`                |
| Settings     | ⚙️    | `settings`              |
| Graph view   | 🕸️   | `gitBranch` or `share2` |
| Tags         | 🏷️   | `tag`                   |
| Link         | 🔗    | `link`                  |
| Bold         | **B** | `bold`                  |
| Italic       | *I*   | `italic`                |
| Code         | `<>`  | `code`                  |
| List         | ☰     | `list`                  |
| Checkbox     | ☑️    | `checkSquare`           |
| Image        | 🖼️   | `image`                 |
| Table        | ⊞     | `table`                 |
| Undo         | ↩️    | `undo`                  |
| Redo         | ↪️    | `redo`                  |
| Delete       | 🗑️   | `trash2`                |
| More options | ⋮     | `moreVertical`          |
| Sidebar      | ☰     | `panelLeft`             |
| Dark mode    | 🌙    | `moon`                  |
| Light mode   | ☀️    | `sun`                   |

**App Launcher Icon**

The app icon has been created and is ready to use.

**Source:** `appicons/app-icon.png`

**Design:**

- Dark slate background (`#0F172A`)
- Infinity symbol with purple-to-cyan gradient
- "N" and "S" letters for NootSpace branding
- 1024 x 1024 px, PNG format

**Setup during project initialization:**

```bash
# Copy the icon to assets folder
cp appicons/app-icon.png assets/images/app-icon.png
```

**flutter_launcher_icons.yaml:**

```yaml
flutter_launcher_icons:
  # iOS
  ios: true
  image_path: "assets/images/app-icon.png"
  remove_alpha_ios: true

  # Android
  android: true
  image_path: "assets/images/app-icon.png"
  adaptive_icon_background: "#0F172A"

  # Windows
  windows:
    generate: true
    image_path: "assets/images/app-icon.png"
    icon_size: 256

  # macOS
  macos:
    generate: true
    image_path: "assets/images/app-icon.png"

  # Linux
  linux:
    generate: true
    image_path: "assets/images/app-icon.png"

  # Web (future)
  web:
    generate: true
    image_path: "assets/images/app-icon.png"
```

**Additional assets available** (for store submissions):

- `appicons/appstore.png` - Apple App Store
- `appicons/playstore.png` - Google Play Store

---

## 6. Implementation Phases

### Phase 1: Foundation (MVP Core)

**Duration Focus:** Core infrastructure and basic functionality

#### 1.1 Project Setup

- [ ] Initialize Flutter project with proper structure
- [ ] Configure pubspec.yaml with required dependencies
- [ ] Set up analysis_options.yaml with strict linting
- [ ] Configure platform-specific settings (Android, iOS, Desktop)
- [ ] Set up Git repository with .gitignore

#### 1.2 Core Infrastructure

- [ ] Implement app theming (dark/light mode)
- [ ] Set up navigation/routing system
- [ ] Create base widgets and UI components
- [ ] Implement error handling framework
- [ ] Set up logging system

#### 1.3 Database Layer

- [ ] Design SQLite schema using Drift
- [ ] Implement database migrations
- [ ] Create DAOs for all entities
- [ ] Implement repository pattern
- [ ] Add database encryption support

#### 1.4 Domain Entities

- [ ] Create Noot entity with Freezed (metadata only)
- [ ] Create Nootspace entity
- [ ] Create Block entity (in-memory only - text, heading, checklist, image, table)
- [ ] Create Tag entity
- [ ] Create Link entity for internal linking
- [ ] Create NootContent entity (holds parsed blocks in memory)

#### 1.5 First-Run Experience

- [ ] Detect first launch (check for config.json)
- [ ] Show welcome/onboarding screens
- [ ] Data folder selection (desktop only)
- [ ] Create default directory structure
- [ ] Create default "Personal" nootspace
- [ ] Create "Welcome to NootSpace" sample noot
- [ ] Initialize SQLite cache from empty state

#### 1.6 File System Services

- [ ] Implement Markdown file read/write service
- [ ] Implement frontmatter parser (YAML)
- [ ] Implement file watcher service
- [ ] Implement config.json read/write service
- [ ] Implement state.json read/write service

### Phase 2: Core Features

#### 2.1 Nootspace Management

- [ ] Implement nootspace CRUD operations
- [ ] Create nootspace selection UI
- [ ] Implement nootspace switching
- [ ] Add nootspace settings/preferences

#### 2.2 Noot Management

- [ ] Implement noot CRUD operations
- [ ] Create noot list/tree view
- [ ] Implement folder/hierarchy structure
- [ ] Add noot metadata (created, modified, tags)
- [ ] Implement noot duplication
- [ ] Auto-update links when noot is renamed
- [ ] Handle broken links when noot is deleted (style differently)

#### 2.3 Block-Based Editor

- [ ] Implement base block editor framework
- [ ] Create text block with rich formatting
- [ ] Create heading blocks (H1-H6)
- [ ] Create checklist/todo blocks
- [ ] Implement block drag-and-drop reordering
- [ ] Add block type conversion
- [ ] Implement undo/redo system

#### 2.4 Daily Noots

- [ ] Configure daily noots folder location (default: `daily/`)
- [ ] Configure daily noot filename format (default: `YYYY-MM-DD.md`)
- [ ] "Open today's daily noot" command
- [ ] Auto-create daily noot if doesn't exist
- [ ] Optional: Daily noot template selection
- [ ] Calendar picker UI for accessing past daily noots

#### 2.5 Templates

- [ ] Templates folder per nootspace (default: `templates/`)
- [ ] "New noot from template" command
- [ ] Template picker UI
- [ ] Variable substitution in templates:
  - `{{date}}` - Current date
  - `{{time}}` - Current time
  - `{{datetime}}` - Date and time
  - `{{title}}` - Noot title (prompted or from filename)
- [ ] Set default template for new noots (optional)

### Phase 3: Advanced Editor Features

#### 3.1 Rich Text Formatting

- [ ] Bold, italic, underline, strikethrough
- [ ] Code inline and code blocks
- [ ] Bullet and numbered lists
- [ ] Blockquotes
- [ ] Horizontal rules

#### 3.2 Media Blocks

- [ ] Image block with local image support
- [ ] Table block with basic editing
- [ ] Embed block for links

**Image Handling Details:**

- **Format:** Standard Markdown `![alt text](path/to/image.png)`
- **Storage:** Images saved to `<nootspace>/assets/` folder
- **Naming:** Auto-generate unique filename (e.g., `image-20251217-143022.png`)
- **Insert methods:**
  - Paste from clipboard (Ctrl+V / Cmd+V)
  - Drag and drop into editor
  - Insert via toolbar/command
  - File picker dialog
- **Supported formats:** PNG, JPG, JPEG, GIF, WebP, SVG
- **Path handling:** Use relative paths from noot location (e.g., `../assets/image.png`)
- **Copy behavior:** Copy image from external location into assets folder

#### 3.3 Internal Linking

- [ ] Implement [[wiki-link]] syntax parsing
- [ ] Support [[noot|display text]] alias syntax
- [ ] Create link autocomplete/suggestions (popup when typing `[[`)
- [ ] Implement backlinks tracking
- [ ] Create backlinks panel UI
- [ ] Click unresolved link to create new noot
- [ ] Link hover preview popup (show noot preview on hover)
- [ ] Detect unlinked mentions (find text matching noot titles without links)

#### 3.4 Navigation Panels

- [ ] Outline panel (Table of Contents from headings)
  - Auto-generate from H1-H6 blocks
  - Click heading to scroll to section
  - Collapsible hierarchy
- [ ] Outgoing links panel (links in current noot)
- [ ] Toggle panels on/off in sidebar

### Phase 4: Search & Organization

#### 4.1 Search System

- [ ] Implement full-text search indexing
- [ ] Create search UI with results
- [ ] Add tag-based filtering
- [ ] Implement search highlighting
- [ ] Add recent searches

#### 4.2 Tags & Metadata

- [ ] Implement tag CRUD operations
- [ ] Create tag management UI
- [ ] Add tag autocomplete
- [ ] Implement tag-based navigation
- [ ] **Inline #tag support:**
  - Parse `#tag-name` syntax in noot body
  - Autocomplete when typing `#`
  - Clickable tags navigate to tag view
  - Unified tag index (frontmatter + inline tags in same table)
  - Sync inline tags to tags table during noot save/index

#### 4.3 Favorites / Quick Access

- [ ] Star/unstar noots (stored in noot frontmatter or state.json)
- [ ] Favorites section in sidebar (above noot tree)
- [ ] Quick access keyboard shortcut
- [ ] Pin noots to top of list option

### Phase 5: Graph View (Optional MVP)

#### 5.1 Graph Visualization

- [x] Implement graph data structure from links
- [x] Create force-directed graph layout
- [x] Implement node rendering
- [x] Add edge/link rendering
- [x] Implement graph navigation (pan, zoom)
- [x] Add node click to open noot

### Phase 6: Polish & Platform Optimization

#### 6.1 Desktop Optimization

- [ ] Implement keyboard shortcuts
- [ ] Add split-pane editor view
- [ ] Create command palette (Ctrl+K)
- [ ] Optimize for larger screens

#### 6.2 Mobile Optimization

- [ ] Implement mobile-friendly navigation
- [ ] Add swipe gestures
- [ ] Optimize touch interactions
- [ ] Implement mobile-specific UI adaptations

#### 6.3 Performance & Polish

- [ ] Optimize large nootspace loading
- [ ] Implement lazy loading for noots
- [ ] Add smooth animations
- [ ] Performance profiling and optimization
- [ ] Memory optimization

---

## 7. Storage Architecture

NootSpace uses a hybrid storage approach: **Markdown files are the source of truth** for user content (like Obsidian), SQLite serves as a cache for fast search/indexing, and JSON handles configuration.

### 7.0 Design Principles

1. **Markdown is authoritative** - The `.md` files are the canonical source of noot content
2. **SQLite is a cache** - Can be rebuilt entirely from Markdown files at any time
3. **User owns their data** - Files can be edited externally, synced via cloud folders, or moved between machines
4. **Offline-first** - Everything works without network connectivity

### 7.1 Directory Structure

**Platform-Specific Root Paths:**

| Platform    | Root Data Location                           | User Configurable? |
| ----------- | -------------------------------------------- | ------------------ |
| **Windows** | `C:\Users\<user>\NootSpace\` or user-selected | Yes                |
| **macOS**   | `~/NootSpace/` or user-selected               | Yes                |
| **Linux**   | `~/NootSpace/` or user-selected               | Yes                |
| **iOS**     | App Documents directory (sandboxed)          | No                 |
| **Android** | App Documents directory (sandboxed)          | No                 |

On desktop platforms, users can choose a custom location (e.g., Dropbox folder for sync). On mobile, data is stored in the app's private sandbox for simplicity and security.

**Directory Tree:**

```
<root>/                                  # Platform-specific root (see above)
├── nootspaces/
│   ├── personal/                        # Nootspace folder
│   │   ├── noots/                       # Noot files
│   │   │   ├── welcome.md
│   │   │   └── projects/                # Folders map to hierarchy
│   │   │       ├── project-a.md
│   │   │       └── project-b.md
│   │   ├── daily/                       # Daily noots
│   │   │   ├── 2025-12-17.md
│   │   │   └── 2025-12-18.md
│   │   ├── assets/                      # Images, attachments
│   │   │   ├── image-001.png
│   │   │   └── document.pdf
│   │   ├── templates/                   # Noot templates
│   │   └── nootspace.json               # Nootspace-specific settings
│   │
│   └── work/                            # Another nootspace
│       ├── noots/
│       ├── daily/
│       ├── assets/
│       ├── templates/
│       └── nootspace.json
│
└── .nootspace/                           # App data (hidden)
    ├── config.json                      # Global app preferences
    ├── state.json                       # UI state (open tabs, sidebar width, etc.)
    └── cache.db                         # SQLite database
```

### 7.2 Storage Responsibilities

| Storage               | Contents                              | Source of Truth? | Purpose                                   |
| --------------------- | ------------------------------------- | ---------------- | ----------------------------------------- |
| **Markdown Files**    | Noot content, frontmatter             | **YES**          | User-owned, portable, editable externally |
| **SQLite (cache.db)** | Search index, parsed links, tags      | No (rebuildable) | Fast queries, relationship tracking       |
| **nootspace.json**    | Nootspace settings, folder colors     | Yes              | Per-nootspace configuration               |
| **config.json**       | Theme, keybindings, global prefs      | Yes              | App-wide settings                         |
| **state.json**        | Open tabs, sidebar state, window size | Yes              | Session restoration                       |

### 7.3 File Formats

**Markdown Files (.md)**

```markdown
---
id: 550e8400-e29b-41d4-a716-446655440000
created: 2025-12-17T10:30:00Z
modified: 2025-12-17T14:22:00Z
tags: [project, planning]
---

# Noot Title

Noot content with [[internal links]] and formatting.

- [ ] Checklist item
- [x] Completed item
```

**config.json**

```json
{
  "version": 1,
  "theme": "dark",
  "accentColor": "#8B5CF6",
  "fontSize": 16,
  "fontFamily": "Inter",
  "editorLineWidth": 720,
  "spellCheck": true,
  "autoSave": true,
  "autoSaveInterval": 30,
  "keyBindings": "default",
  "showLineNumbers": false,
  "defaultNootspace": "personal",
  "dailyNoots": {
    "enabled": true,
    "folder": "daily",
    "format": "YYYY-MM-DD",
    "template": null
  },
  "templates": {
    "folder": "templates",
    "defaultTemplate": null
  },
  "editor": {
    "mode": "livePreview"
  },
  "panels": {
    "showOutline": true,
    "showBacklinks": true,
    "showOutgoingLinks": false
  }
}
```

**nootspace.json**

```json
{
  "version": 1,
  "name": "Personal",
  "icon": "folder",
  "color": "#8B5CF6",
  "sortOrder": "modified",
  "excludePatterns": ["_archive/*"],
  "created": "2025-12-17T10:00:00Z"
}
```

**state.json**

```json
{
  "version": 1,
  "activeNootspace": "personal",
  "openTabs": [
    { "type": "noot", "path": "noots/welcome.md" },
    { "type": "noot", "path": "noots/projects/project-a.md" }
  ],
  "activeTab": 0,
  "sidebarWidth": 280,
  "sidebarCollapsed": false,
  "windowBounds": { "x": 100, "y": 100, "width": 1400, "height": 900 }
}
```

### 7.4 Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Actions                            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Application Layer                          │
│  (Riverpod providers coordinate between storage systems)        │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│  File System  │       │    SQLite     │       │     JSON      │
│  (Markdown)   │       │  (cache.db)   │       │   (config)    │
├───────────────┤       ├───────────────┤       ├───────────────┤
│ Noot content  │       │ Search index  │       │ Preferences   │
│ Assets        │       │ Metadata      │       │ UI state      │
│               │       │ Links/Tags    │       │ Nootspace cfg │
└───────────────┘       └───────────────┘       └───────────────┘
```

### 7.5 Sync Between File System and SQLite

When changes occur:

1. **User edits noot** → Save to `.md` file → Update SQLite index
2. **External file change detected** → Re-parse `.md` → Update SQLite index
3. **App startup** → Scan nootspace folders → Reconcile with SQLite cache

The SQLite database is a **cache** that can be rebuilt from the Markdown files at any time.

### 7.6 File Conflict Resolution

When external file changes are detected while the user has the same noot open:

**Strategy: Auto-reload + Prompt if Unsaved**

```
┌─────────────────────────────────────────────────────────────┐
│                  External Change Detected                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────────┐
              │ Does user have unsaved      │
              │ changes to this noot?       │
              └─────────────────────────────┘
                     │              │
                    YES             NO
                     │              │
                     ▼              ▼
         ┌───────────────────┐    ┌───────────────────┐
         │ Show conflict     │    │ Auto-reload file  │
         │ dialog            │    │ silently          │
         └───────────────────┘    └───────────────────┘
```

**Conflict Dialog Options:**

| Option               | Behavior                                              |
| -------------------- | ----------------------------------------------------- |
| **Keep my changes**  | Save in-app version, overwrite file                   |
| **Use file version** | Discard in-app changes, reload from file              |
| **Keep both**        | Save in-app version as `noot_conflict_<timestamp>.md` |

**File Watching Implementation:**

- Use `watcher` package to monitor nootspace directories
- Debounce rapid file changes (wait 500ms after last change)
- Ignore changes triggered by the app itself (track recent saves)
- On desktop: Watch continuously while app is running
- On mobile: Check for changes when app resumes from background

### 7.7 Cache Rebuild

The SQLite cache can be rebuilt from Markdown files:

```dart
Future<void> rebuildCache(String nootspaceId) async {
  // 1. Clear existing cache for nootspace
  // 2. Scan all .md files in nootspace/noots/
  // 3. Parse frontmatter and content
  // 4. Extract internal links
  // 5. Rebuild FTS index
  // 6. Rebuild link graph
}
```

**Triggers for cache rebuild:**

- First app launch
- User manually triggers "Rebuild Index" in settings
- Detected file system inconsistency
- Nootspace folder moved or restored from backup

---

## 8. Database Schema

The SQLite database serves as a **cache/index only** - not a content store. Block content is parsed in-memory from Markdown files when noots are opened.

### 8.1 What's Cached vs In-Memory

| Data                   | Storage            | Reason                                |
| ---------------------- | ------------------ | ------------------------------------- |
| Noot metadata          | SQLite             | Fast listing, sorting, filtering      |
| Full-text search index | SQLite (FTS5)      | Fast search without reading all files |
| Links between noots    | SQLite             | Graph view, backlinks queries         |
| Tags                   | SQLite             | Tag management, filtering             |
| **Block content**      | **In-memory only** | Parsed from .md file when noot opens  |

### 8.2 Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐
│  Nootspace  │       │    Noot     │
├─────────────┤       ├─────────────┤
│ id (PK)     │──────<│ id (PK)     │
│ name        │       │ nootspace_id│
│ description │       │ parent_id   │
│ created_at  │       │ title       │
│ updated_at  │       │ file_path   │
│ settings    │       │ created_at  │
└─────────────┘       │ updated_at  │
                      │ is_folder   │
                      └─────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│  Noot_Tag   │       │    Link     │       │    Tag      │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ noot_id(FK) │       │ id (PK)     │       │ id (PK)     │
│ tag_id (FK) │       │ source_noot │       │ name        │
└─────────────┘       │ target_noot │       │ color       │
                      │ link_text   │       │ nootspace_id│
                      │ created_at  │       └─────────────┘
                      └─────────────┘

                      ┌─────────────┐
                      │  Noots_FTS  │ (Virtual Table)
                      ├─────────────┤
                      │ noot_id     │
                      │ title       │
                      │ content     │ ← Plain text extracted from .md
                      └─────────────┘
```

### 8.3 Table Definitions

```sql
-- Nootspaces table (metadata only)
CREATE TABLE nootspaces (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    settings TEXT,  -- JSON for nootspace settings
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- Noots table (metadata only - content is in .md files)
CREATE TABLE noots (
    id TEXT PRIMARY KEY,
    nootspace_id TEXT NOT NULL REFERENCES nootspaces(id) ON DELETE CASCADE,
    parent_id TEXT REFERENCES noots(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    file_path TEXT NOT NULL,  -- Relative path within nootspace (e.g., "noots/projects/my-noot.md")
    is_folder INTEGER NOT NULL DEFAULT 0,
    icon TEXT,
    cover_image TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    UNIQUE(nootspace_id, file_path)
);

-- Tags table
CREATE TABLE tags (
    id TEXT PRIMARY KEY,
    nootspace_id TEXT NOT NULL REFERENCES nootspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT,
    created_at INTEGER NOT NULL,
    UNIQUE(nootspace_id, name)
);

-- Noot-Tag junction table
CREATE TABLE noot_tags (
    noot_id TEXT NOT NULL REFERENCES noots(id) ON DELETE CASCADE,
    tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (noot_id, tag_id)
);

-- Links table (for internal [[links]] - enables backlinks and graph view)
CREATE TABLE links (
    id TEXT PRIMARY KEY,
    source_noot_id TEXT NOT NULL REFERENCES noots(id) ON DELETE CASCADE,
    target_noot_id TEXT REFERENCES noots(id) ON DELETE SET NULL,  -- NULL if target doesn't exist yet
    link_text TEXT NOT NULL,  -- The text inside [[link_text]]
    created_at INTEGER NOT NULL,
    UNIQUE(source_noot_id, link_text)
);

-- Full-text search virtual table (content extracted from .md files during indexing)
CREATE VIRTUAL TABLE noots_fts USING fts5(
    noot_id UNINDEXED,  -- For joining back to noots table
    title,
    content,            -- Plain text content (Markdown stripped)
    tokenize='porter unicode61'
);

-- Indexes
CREATE INDEX idx_noots_nootspace ON noots(nootspace_id);
CREATE INDEX idx_noots_parent ON noots(parent_id);
CREATE INDEX idx_noots_filepath ON noots(nootspace_id, file_path);
CREATE INDEX idx_links_source ON links(source_noot_id);
CREATE INDEX idx_links_target ON links(target_noot_id);
CREATE INDEX idx_links_text ON links(link_text);
```

### 8.4 Block Parsing (In-Memory)

Blocks are **not stored in the database**. When a noot is opened:

```dart
/// Load noot content from Markdown file
Future<NootContent> loadNootContent(Noot noot) async {
  // 1. Read .md file from disk
  final markdown = await File(noot.absolutePath).readAsString();

  // 2. Parse frontmatter (YAML between --- markers)
  final parsed = parseFrontMatter(markdown);

  // 3. Parse Markdown body into blocks (in-memory)
  final blocks = markdownToBlocks(parsed.content);

  return NootContent(
    metadata: parsed.frontMatter,
    blocks: blocks,  // List<Block> - exists only in memory
  );
}

/// Save noot content to Markdown file
Future<void> saveNootContent(Noot noot, List<Block> blocks) async {
  // 1. Serialize blocks to Markdown
  final markdown = blocksToMarkdown(blocks);

  // 2. Add frontmatter
  final content = addFrontMatter(markdown, noot.metadata);

  // 3. Write to .md file
  await File(noot.absolutePath).writeAsString(content);

  // 4. Update cache (FTS index, links, metadata)
  await updateNootCache(noot, markdown);
}
```

This approach keeps the database small and ensures Markdown files are always the source of truth.

---

## 9. Core Components Specification

### 9.1 Block Editor Architecture

The block editor is the central component of NootSpace. Blocks exist **in-memory only** - they are parsed from Markdown files when a noot opens and serialized back to Markdown when saving.

```dart
// Block type enumeration
enum BlockType {
  text,
  heading1,
  heading2,
  heading3,
  checklist,
  bulletList,
  numberedList,
  code,
  quote,
  image,
  table,
  divider,
}

// Block model (IN-MEMORY ONLY - not persisted to database)
@freezed
class Block with _$Block {
  const factory Block({
    required String id,          // Generated when parsing, not stored
    required BlockType type,
    required Map<String, dynamic> content,
    required int order,
  }) = _Block;
}

// Container for a noot's content (in-memory)
@freezed
class NootContent with _$NootContent {
  const factory NootContent({
    required List<Block> blocks,
    required Map<String, dynamic> frontMatter,
    required String rawMarkdown,  // Original markdown for fallback
  }) = _NootContent;
}
```

### 9.2 Internal Linking System

The linking system parses `[[noot-title]]` and `[[noot-title|display text]]` syntax and maintains bidirectional links:

**Supported Link Syntax:**

| Syntax                       | Rendered As    | Noots                    |
| ---------------------------- | -------------- | ------------------------ |
| `[[noot-name]]`              | noot-name      | Links to noot-name.md    |
| `[[noot-name\|Custom Text]]` | Custom Text    | Alias syntax             |
| `[[folder/noot]]`            | noot           | Links to folder/noot.md  |
| `[[noot#heading]]`           | noot > heading | Link to specific heading |

```dart
class LinkParserService {
  // Regex pattern for wiki-links (with optional alias)
  static final linkPattern = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
  // Group 1: target noot, Group 2: display text (optional)

  // Extract all links from content
  List<ParsedLink> extractLinks(String content);

  // Replace link text with actual noot references
  String resolveLinks(String content, Map<String, Noot> nootMap);

  // Get backlinks for a noot
  Future<List<Noot>> getBacklinks(String nootId);

  // Check if link target exists
  bool isResolvedLink(String linkText, Map<String, Noot> nootMap);
}

@freezed
class ParsedLink with _$ParsedLink {
  const factory ParsedLink({
    required String target,       // The noot being linked to
    required String? displayText, // Optional alias text
    required int startOffset,     // Position in content
    required int endOffset,
  }) = _ParsedLink;
}
```

**Link Behaviors:**

| Scenario              | Behavior                               |
| --------------------- | -------------------------------------- |
| Click resolved link   | Navigate to target noot                |
| Click unresolved link | Prompt to create new noot              |
| Hover on link         | Show preview popup                     |
| Noot renamed          | Auto-update all incoming links         |
| Noot deleted          | Mark links as broken (different style) |

### 9.3 Search Service

Full-text search using SQLite FTS5:

```dart
abstract class SearchRepository {
  Future<List<SearchResult>> search(String query, {
    String? nootspaceId,
    List<String>? tagIds,
    int limit = 50,
  });

  Future<void> indexNoot(Noot noot);
  Future<void> removeFromIndex(String nootId);
  Future<void> rebuildIndex();
}
```

### 9.4 State Management Structure

```dart
// Nootspace state
@riverpod
class NootspaceNotifier extends _$NootspaceNotifier {
  @override
  Future<List<Nootspace>> build() async {
    return ref.read(nootspaceRepositoryProvider).getAllNootspaces();
  }

  Future<void> createNootspace(String name);
  Future<void> deleteNootspace(String id);
  Future<void> updateNootspace(Nootspace nootspace);
}

// Current nootspace
@riverpod
class CurrentNootspace extends _$CurrentNootspace {
  @override
  String? build() => null;  // No nootspace selected initially

  void select(String nootspaceId);
}

// Noots in current nootspace
@riverpod
Future<List<Noot>> nootspaceNoots(NootspaceNootsRef ref) async {
  final nootspaceId = ref.watch(currentNootspaceProvider);
  if (nootspaceId == null) return [];
  return ref.read(nootRepositoryProvider).getNootsByNootspace(nootspaceId);
}

// Editor state
@riverpod
class EditorNotifier extends _$EditorNotifier {
  @override
  EditorState build(String nootId) => EditorState.initial();

  void updateBlock(String blockId, Map<String, dynamic> content);
  void addBlock(BlockType type, int index);
  void removeBlock(String blockId);
  void reorderBlocks(int oldIndex, int newIndex);
  void undo();
  void redo();
}
```

---

## 10. Testing Strategy

### 10.1 Test Categories

| Category          | Coverage Target | Focus Areas                       |
| ----------------- | --------------- | --------------------------------- |
| Unit Tests        | 80%+            | Domain logic, services, utilities |
| Widget Tests      | 70%+            | UI components, user interactions  |
| Integration Tests | Key flows       | End-to-end user journeys          |

### 10.2 Test Structure

```
test/
├── domain/
│   ├── entities/
│   │   ├── noot_test.dart
│   │   ├── block_test.dart
│   │   └── nootspace_test.dart
│   └── value_objects/
├── data/
│   ├── repositories/
│   │   ├── noot_repository_test.dart
│   │   └── nootspace_repository_test.dart
│   └── datasources/
├── application/
│   ├── providers/
│   │   ├── noot_providers_test.dart
│   │   └── search_providers_test.dart
│   └── services/
│       ├── link_parser_test.dart
│       └── markdown_service_test.dart
└── presentation/
    ├── widgets/
    │   ├── block_editor_test.dart
    │   └── sidebar_test.dart
    └── pages/
        ├── home_page_test.dart
        └── editor_page_test.dart

integration_test/
├── app_test.dart
├── nootspace_flow_test.dart
├── noot_editing_flow_test.dart
└── search_flow_test.dart
```

### 10.3 Key Test Scenarios

**Unit Tests**

- Block content serialization/deserialization
- Link parsing and extraction
- Search query building
- Tag management logic
- Undo/redo stack operations

**Widget Tests**

- Block editor interactions
- Sidebar navigation
- Search results display
- Theme switching
- Responsive layout changes

**Integration Tests**

- Create nootspace → create noot → edit → save
- Internal linking workflow
- Search and navigate to results
- Tag creation and filtering
- Import/export operations

---

## 11. Deployment Strategy

### 11.1 Build Configurations

| Platform | Build Command                     | Output       |
| -------- | --------------------------------- | ------------ |
| Android  | `flutter build apk --release`     | APK/AAB      |
| iOS      | `flutter build ios --release`     | IPA          |
| Windows  | `flutter build windows --release` | MSIX         |
| macOS    | `flutter build macos --release`   | DMG          |
| Linux    | `flutter build linux --release`   | AppImage/DEB |

### 11.2 Release Checklist

- [ ] Version bump in pubspec.yaml
- [ ] Update changelog
- [ ] Run full test suite
- [ ] Build for all target platforms
- [ ] Test on physical devices
- [ ] Generate release noots
- [ ] Tag release in Git

### 11.3 Distribution Channels

| Platform | Distribution                           |
| -------- | -------------------------------------- |
| Android  | Google Play Store, APK direct download |
| iOS      | Apple App Store, TestFlight            |
| Windows  | Microsoft Store, GitHub Releases       |
| macOS    | Mac App Store, GitHub Releases         |
| Linux    | Snap Store, Flathub, GitHub Releases   |

### 11.4 Versioning Strategy

Follow **Semantic Versioning** (semver):

```
MAJOR.MINOR.PATCH (e.g., 1.2.3)
```

| Component | When to Increment                  |
| --------- | ---------------------------------- |
| **MAJOR** | Breaking changes, major redesigns  |
| **MINOR** | New features (backward compatible) |
| **PATCH** | Bug fixes, minor improvements      |

**Build Number Format:** `YYYYMMDDNN` (e.g., `2025121701`)

**Version in pubspec.yaml:**

```yaml
version: 1.0.0+2025121701
#        ^     ^
#        |     Build number
#        Semantic version
```

### 11.5 CI/CD Pipeline

**GitHub Actions Workflows:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  build:
    needs: test
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build [platform] --release
```

**Automated Tasks:**

- Run tests on every PR
- Build all platforms on merge to `main`
- Generate release artifacts on git tags
- Upload to GitHub Releases

### 11.6 Code Signing

| Platform    | Requirement                                         |
| ----------- | --------------------------------------------------- |
| **iOS**     | Apple Developer certificate + provisioning profile  |
| **macOS**   | Developer ID certificate (for notarization)         |
| **Android** | Keystore file (keep secure, backed up)              |
| **Windows** | Code signing certificate (optional but recommended) |

**Store signing keys securely** - Use GitHub Secrets or similar for CI/CD.

---

## 12. Risk Assessment & Mitigation

| Risk                                          | Impact | Likelihood | Mitigation                                                |
| --------------------------------------------- | ------ | ---------- | --------------------------------------------------------- |
| Block editor performance with large documents | High   | Medium     | Implement virtualized rendering, lazy loading             |
| Cross-platform UI inconsistencies             | Medium | High       | Extensive testing on all platforms, adaptive widgets      |
| SQLite limitations on mobile                  | Medium | Low        | Proper indexing, query optimization, pagination           |
| Graph view performance with many nodes        | High   | Medium     | Limit visible nodes, implement clustering                 |
| Data loss from crashes                        | High   | Low        | Auto-save, WAL mode for SQLite, crash recovery            |
| File permission issues (mobile)               | Medium | Medium     | Graceful error handling, clear user messaging             |
| External file edit conflicts                  | Medium | Medium     | Conflict detection, resolution dialog (see 7.6)           |
| super_editor package limitations              | Medium | Medium     | Abstract editor interface for potential swap              |
| Schema/config migration failures              | High   | Low        | Versioned migrations, validation, rollback support        |
| Large nootspace initial scan                  | Medium | Medium     | Progress indicator, background indexing, incremental scan |

---

## 13. Development Guidelines

### 13.1 Code Style

- Follow official Dart style guide
- Use `flutter_lints` package with strict rules
- Maximum line length: 80 characters
- Use meaningful variable and function names
- Document public APIs with dartdoc comments

### 13.2 Git Workflow

- Main branch: `main` (stable releases)
- Development branch: `develop` (integration)
- Feature branches: `feature/description`
- Bug fix branches: `fix/description`
- Use conventional commits format

### 13.3 PR Requirements

- All tests passing
- Code review by at least one developer
- No linting errors
- Documentation updated if needed

---

## 14. Future Considerations (Post-MVP)

These features are documented for Phase 2 planning but are **out of scope** for MVP:

1. **Cloud Sync** - Firebase or custom backend synchronization
2. **Real-time Collaboration** - Conflict resolution, presence indicators
3. **Plugin System** - Extension API for third-party features
4. **Task Management** - Kanban boards, calendar integration
5. **Advanced Graph Analytics** - Clustering, filtering, graph queries
6. **Media Embedding** - PDF, audio, video support
7. **AI Features** - Smart suggestions, auto-tagging, summarization

---

## Appendix A: Keyboard Shortcuts (Desktop)

### General

| Action                     | Windows/Linux | macOS       |
| -------------------------- | ------------- | ----------- |
| New Noot                   | Ctrl+N        | Cmd+N       |
| Save                       | Ctrl+S        | Cmd+S       |
| Close Tab                  | Ctrl+W        | Cmd+W       |
| Settings                   | Ctrl+,        | Cmd+,       |
| Toggle Sidebar             | Ctrl+\        | Cmd+\       |
| Command Palette            | Ctrl+Shift+P  | Cmd+Shift+P |
| Quick Open (file switcher) | Ctrl+O        | Cmd+O       |
| Quick Search (content)     | Ctrl+P        | Cmd+P       |
| Graph View                 | Ctrl+G        | Cmd+G       |
| Open Today's Daily Noot    | Ctrl+Alt+D    | Cmd+Opt+D   |
| New Noot from Template     | Ctrl+Shift+N  | Cmd+Shift+N |
| Toggle Outline Panel       | Ctrl+Shift+O  | Cmd+Shift+O |
| Toggle Backlinks Panel     | Ctrl+Shift+B  | Cmd+Shift+B |
| Star/Unstar Noot           | Ctrl+Shift+F  | Cmd+Shift+F |

### Text Formatting

| Action        | Windows/Linux | macOS       |
| ------------- | ------------- | ----------- |
| Bold          | Ctrl+B        | Cmd+B       |
| Italic        | Ctrl+I        | Cmd+I       |
| Underline     | Ctrl+U        | Cmd+U       |
| Strikethrough | Ctrl+Shift+S  | Cmd+Shift+S |
| Inline Code   | Ctrl+E        | Cmd+E       |
| Link          | Ctrl+K        | Cmd+K       |

### Block Operations

| Action                 | Windows/Linux          | macOS                  |
| ---------------------- | ---------------------- | ---------------------- |
| New Block Below        | Enter                  | Enter                  |
| New Block Above        | Ctrl+Shift+Enter       | Cmd+Shift+Enter        |
| Delete Block           | Backspace (when empty) | Backspace (when empty) |
| Move Block Up          | Ctrl+Shift+↑           | Cmd+Shift+↑            |
| Move Block Down        | Ctrl+Shift+↓           | Cmd+Shift+↓            |
| Duplicate Block        | Ctrl+D                 | Cmd+D                  |
| Convert to H1          | Ctrl+Alt+1             | Cmd+Opt+1              |
| Convert to H2          | Ctrl+Alt+2             | Cmd+Opt+2              |
| Convert to H3          | Ctrl+Alt+3             | Cmd+Opt+3              |
| Convert to Checklist   | Ctrl+Alt+4             | Cmd+Opt+4              |
| Convert to Bullet List | Ctrl+Alt+5             | Cmd+Opt+5              |
| Convert to Code Block  | Ctrl+Alt+6             | Cmd+Opt+6              |
| Toggle Checkbox        | Ctrl+Enter             | Cmd+Enter              |

### Navigation

| Action              | Windows/Linux | macOS       |
| ------------------- | ------------- | ----------- |
| Go to Previous Noot | Alt+←         | Opt+←       |
| Go to Next Noot     | Alt+→         | Opt+→       |
| Focus Noot Tree     | Ctrl+Shift+E  | Cmd+Shift+E |
| Focus Editor        | Escape        | Escape      |

### Editing

| Action           | Windows/Linux          | macOS       |
| ---------------- | ---------------------- | ----------- |
| Undo             | Ctrl+Z                 | Cmd+Z       |
| Redo             | Ctrl+Y or Ctrl+Shift+Z | Cmd+Shift+Z |
| Select All       | Ctrl+A                 | Cmd+A       |
| Find in Noot     | Ctrl+F                 | Cmd+F       |
| Find and Replace | Ctrl+H                 | Cmd+H       |

---

## Appendix B: Block Types Reference

| Block Type    | Content Structure                                   | Features                |
| ------------- | --------------------------------------------------- | ----------------------- |
| Text          | `{ "text": "...", "formatting": [...] }`            | Rich text, inline links |
| Heading       | `{ "level": 1-6, "text": "..." }`                   | Collapsible sections    |
| Checklist     | `{ "items": [{ "text": "...", "checked": bool }] }` | Toggle completion       |
| Bullet List   | `{ "items": ["...", "..."] }`                       | Nested lists            |
| Numbered List | `{ "items": ["...", "..."], "start": 1 }`           | Auto-numbering          |
| Code          | `{ "code": "...", "language": "..." }`              | Syntax highlighting     |
| Quote         | `{ "text": "...", "citation": "..." }`              | Block styling           |
| Image         | `{ "path": "...", "alt": "...", "caption": "..." }` | Resize, alignment       |
| Table         | `{ "rows": [[...], [...]], "headers": [...] }`      | Add/remove rows/cols    |
| Divider       | `{}`                                                | Horizontal rule         |

---

*This implementation plan will be updated as the project progresses and requirements evolve.*
