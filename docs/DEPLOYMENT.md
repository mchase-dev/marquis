# Deployment Guide

This guide covers Marquis's CI/CD pipelines, release process, and platform-specific build details.

---

## CI/CD Overview

Marquis uses GitHub Actions with two workflows:

| Workflow                                      | Trigger           | Purpose                                    |
| --------------------------------------------- | ----------------- | ------------------------------------------ |
| **CI** (`.github/workflows/ci.yml`)           | Push/PR to `main` | Lint and test                              |
| **Release** (`.github/workflows/release.yml`) | Push tag `v*`     | Build all platforms, create GitHub Release |

---

## CI Pipeline

**File:** `.github/workflows/ci.yml`

Runs on every push to `main` and every pull request targeting `main`.

1. Checkout code
2. Set up Flutter (stable channel, with caching)
3. `flutter pub get`
4. `flutter analyze --no-fatal-infos` — static analysis
5. `flutter test` — all 85 tests

Runs on `ubuntu-latest` only. Typical runtime: 3–5 minutes.

---

## Release Pipeline

**File:** `.github/workflows/release.yml`

Triggered when a tag matching `v*` is pushed (e.g., `v1.0.0`, `v1.2.3-beta`).

### Build Matrix

Three parallel platform jobs run simultaneously:

| Job             | Runner           | Build Command                     | Artifacts                                          |
| --------------- | ---------------- | --------------------------------- | -------------------------------------------------- |
| `build-windows` | `windows-latest` | `flutter build windows --release` | `Marquis-windows.zip`, `Marquis-windows-setup.exe` |
| `build-macos`   | `macos-latest`   | `flutter build macos --release`   | `Marquis-macos.tar.gz`, `Marquis-macos.dmg`        |
| `build-linux`   | `ubuntu-latest`  | `flutter build linux --release`   | `Marquis-linux.tar.gz`, `marquis_X.Y.Z_amd64.deb`  |

Each platform job produces both a raw archive and an installer artifact.

After all builds complete, the `create-release` job:

1. Downloads all artifacts
2. Creates a GitHub Release with auto-generated release notes
3. Attaches all platform artifacts to the release

### Platform Notes

**Windows:** Uses PowerShell's `Compress-Archive` to create the zip file. Builds an Inno Setup installer (`.exe`) with:

- Start Menu and Desktop shortcuts
- `.md` and `.markdown` file associations (optional during install)
- Uninstaller
- The installer script lives at `installers/windows/marquis.iss`

**macOS:** Uses `create-dmg` (installed via Homebrew) to produce a `.dmg` for drag-and-drop installation. Builds are currently unsigned.

**Linux:** Installs `ninja-build`, `libgtk-3-dev`, `libblkid-dev`, and `liblzma-dev` before building. Builds a `.deb` package that:

- Installs to `/opt/marquis/`
- Creates a `/usr/bin/marquis` wrapper script
- Installs a `.desktop` entry (`installers/linux/marquis.desktop`)
- Generates a 256x256 app icon via ImageMagick

---

## Creating a Release

### 1. Update the Version

Edit `pubspec.yaml`:

```yaml
version: 1.1.2   # major.minor.patch
```

### 2. Commit and Tag

```bash
git add pubspec.yaml
git commit -m "Bump version to 1.1.1"
git tag v1.1.1
git push origin main --tags
```

### 3. Monitor the Build

Go to the repository's **Actions** tab to watch the release workflow. All 3 platform builds run in parallel. The `create-release` job runs after all builds succeed.

### 4. Verify the Release

Navigate to the **Releases** page. You should see:

- Auto-generated release notes (from commit messages since last tag)
- 6 attached artifacts:
  - `Marquis-windows.zip` (Windows archive)
  - `Marquis-windows-setup.exe` (Windows installer)
  - `Marquis-macos.tar.gz` (macOS archive, unsigned)
  - `Marquis-macos.dmg` (macOS installer, unsigned)
  - `Marquis-linux.tar.gz` (Linux archive)
  - `marquis_X.Y.Z_amd64.deb` (Debian/Ubuntu installer)

### 5. Edit Release Notes (Optional)

Click **Edit** on the release to add highlights, breaking changes, or upgrade instructions.

---

## GitHub Actions Minutes

The repository uses GitHub's free tier (2,000 Linux minutes/month for private repos). Multipliers apply for non-Linux runners:

| Runner           | Rate | Est. per Release                |
| ---------------- | ---- | ------------------------------- |
| `ubuntu-latest`  | 1x   | ~5 min (Linux + create-release) |
| `macos-latest`   | 10x  | ~100 min (macOS)                |
| `windows-latest` | 2x   | ~16 min (Windows)               |
| **Total**        |      | **~121 min**                    |

This allows roughly 16 full releases per month on the free tier, plus CI runs (~5 min each at 1x).

### Saving Minutes

- macOS builds are the most expensive (10x multiplier).
- CI runs on `ubuntu-latest` only (1x rate).
- Flutter dependency caching is enabled to reduce install time.
- Marquis builds for 3 desktop platforms only (no Android/iOS), keeping costs lower than mobile-inclusive projects.

---

## Local Release Builds

To build release artifacts locally without CI:

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux (requires GTK3 dev headers)
flutter build linux --release
```

See the [Development Guide](DEVELOPMENT.md) for build output paths.

---

## Versioning Strategy

Marquis uses semantic versioning: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR:** Breaking changes to file format or user-facing behavior
- **MINOR:** New features, backwards-compatible
- **PATCH:** Bug fixes
- **BUILD:** Numeric build identifier

The version in `pubspec.yaml` is the source of truth. Git tags should match (e.g., `v1.0.0` for version `1.0.0`).

---

## Installer Details

### Windows — Inno Setup

The installer script at `installers/windows/marquis.iss` configures:

- Install to `%ProgramFiles%\Marquis`
- Start Menu group with launch and uninstall shortcuts
- Optional desktop shortcut
- Optional `.md` and `.markdown` file associations (per-user registry)
- Modern wizard style with app icon
- LZMA2 compression

The version is passed at compile time: `ISCC.exe /DAppVersion=X.Y.Z marquis.iss`

### Linux — .deb Package

The `.deb` is built inline in the release workflow:

- Package installs to `/opt/marquis/`
- Wrapper script at `/usr/bin/marquis`
- Desktop entry from `installers/linux/marquis.desktop`
- Dependencies: `libgtk-3-0`, `libblkid1`, `liblzma5`
- Icon generated from `assets/icons/app_icon_master.png` at 256x256

### macOS — DMG

Uses `create-dmg` with a 600x400 window. The DMG contains `Marquis.app` for drag-and-drop installation. Currently unsigned — macOS will show a Gatekeeper warning on first launch.

---

## Next Steps

Platform installers are generated automatically without code signing. Future improvements:

- **Code signing:** Sign Windows installer with Authenticode, macOS app with Apple Developer certificate
- **Notarization:** Notarize macOS builds to avoid Gatekeeper warnings
- **Auto-update:** Investigate Sparkle (macOS) or similar update frameworks
- **Store submissions:** Microsoft Store, Mac App Store (would require sandboxing review)
- **Linux packaging:** Snap, Flatpak, or AppImage for broader distribution
