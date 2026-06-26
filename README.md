# GATEletics

[![Build & Release](https://github.com/vishnunandan555/gateletics/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/vishnunandan555/gateletics/actions/workflows/release.yml)
[![Version](https://img.shields.io/badge/version-1.2.0--stable-emerald.svg)](https://github.com/vishnunandan555/gateletics/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

A minimalist, high-performance, offline-first syllabus tracker designed specifically for the Graduate Aptitude Test in Engineering (GATE) Exam. It enables aspirants to logically organize subjects, define syllabus weights, and track video-course or syllabus completion progress.

**Live Web Version:** You can access and run the complete web application directly in your browser at **[gateletics.vercel.app](https://gateletics.vercel.app/)** (with full offline PWA capabilities).

---

## 🛠️ Architecture & Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart SDK `^3.12.0`)
- **State Management:** [Riverpod](https://riverpod.dev) (Modern, type-safe reactive state tracking)
- **Database Engine:** [Drift](https://drift.simonbinder.eu) (Robust, compile-safe relational SQLite wrapper)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (Declarative routing)

---

## 📂 Local Data Storage Specifications

GATEletics is fully offline-first, requiring no network connection to operate. All database instances, progress entries, and custom configurations are stored locally on the host device.

| Platform | Database Type | Storage Directory / File Path | Permission Prompts |
| :--- | :--- | :--- | :--- |
| **Android** | SQLite | `/data/data/com.vishnunandan.gateletics/app_flutter/gateletics.db` | None (App-private storage) |
| **Linux** | SQLite | `~/Documents/gateletics/gateletics.db` | None (User directory) |
| **Windows** | SQLite | `C:\Users\<username>\Documents\gateletics\gateletics.db` | None (User directory) |
| **Web** | IndexedDB | Browser-managed client-side database storage via local WebAssembly | None (Standard HTML5 storage) |

### Note on Web Storage (IndexedDB + WebAssembly)
* **100% Self-Contained Web Target:** To support zero-dependency SQLite connections on Web without slow external CDN dependencies, both `sql-wasm.js` and `sql-wasm.wasm` are stored locally in the `/web` static root.
* **Concurrent Boot Performance:** Preload directives (`<link rel="preload">`) are embedded in the `<head>` of `index.html` to instruct the browser to download WebAssembly assets concurrently, ensuring a super-fast, lag-free boot phase.
* **No explicit permission prompt** is requested or required, making the user experience frictionless.
* Data is persisted per website origin (Same-Origin Policy).

---


## ✨ Features

- **Progress Analytics:** Overall exam completion index visualized using a high-fidelity animated progress ring.
- **Relational Structure:** Subjects are dynamically assigned to parent Categories (Syllabus Areas) with progress rolling up automatically.
- **Customizable Subjects:** Tap-to-edit video syllabus counts, customized source channels, and direct course/playlist URLs.
- **Pre-configured Presets:** Instantly bootstrap your tracking with complete syllabus and video count presets (e.g., GoClasses/YouTube).
- **JSON Import/Export:** Secure backup utility that lets you export or import your progress as a relational JSON schema, facilitating backup portability.
- **Premium Snapping Settings Panel:** A restructured settings bottom sheet using a custom `DraggableScrollableSheet` with:
  - **Height Locking:** Covers exactly 75% of the screen height upon opening, scrollable up to 95%, or drag-to-dismiss.
  - **Optimized Lazy Scrolling:** Built using a lazy `ListView` coordinated with the sheet's controller to eliminate drag stuttering and maximize frame rates.

## 🌐 Web Deployment (Vercel)

The web target of GATEletics is designed for hosting on Vercel:
- **Automated CI/CD Pipeline:** The application uses GitHub Actions to compile Dart code and deploy the pre-built web assets (`/build/web`) to Vercel instantly.
- **Offline PWA Support:** On first load, the browser registers a service worker that caches all application resources—including local SQLite WebAssembly and style binaries—enabling the web app to run 100% offline subsequently.

---

## 🚀 Developer Setup

### Prerequisites
- Flutter SDK `3.44.0` or higher
- Dart SDK `3.12` or higher

### 1. Clone & Fetch Dependencies
```bash
git clone https://github.com/vishnunandan555/gateletics.git
cd gateletics
flutter pub get
```

### 2. Generate Relational Database & Models
This project utilizes Drift's code generation engine to construct the SQL interface and model bindings.
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Execution
Run the app locally in debug mode:
```bash
flutter run
```

To run specifically on Web (Chrome):
```bash
flutter run -d chrome
```

To build a release binary (e.g., for Linux):
```bash
flutter build linux
```

## 🌟 Version 1.2.0 Highlights

- **Firebase Authentication & Cloud Sync**: Seamlessly sign in with Google to enable automatic, offline-first progress backups.
- **Intelligent Database Merging**: If you log in on a new device or have offline edits, the app prompts you to merge your data, keeping the highest progress for each subject.
- **Unified Backup Service**: Decoupled database import/export operations into a pure data serialization service, optimizing code and reducing footprint.

## 🌟 Version 1.1.5 Highlights

- **Completed Category Collapsing**: Categories that are 100% complete now collapse automatically by default, allowing user-toggled expansion with a single tap on the header.
- **Snug & Balanced Layout Styling**: Collapsed category headers are styled with a clean rounded border container matching their theme color, featuring symmetric dynamic vertical spacing that automatically adjusts based on neighboring collapsed categories.
- **Syllabus Preset Short Forms**: Shortened default category preset names for syllabus tracking (e.g. `C PROG.`, `DS`, `CD`, `OS`, `CN`, `Aptitude`) to fit mobile layouts better.
- **Deferred Auto-Sorting**: Improved the Auto-Sort setting so that categories only re-order on tab navigation or app restart, preventing abrupt list jumps during active progress tracking.
- **Category Font Size Setting**: Added a customization option in Settings to scale the category header font size (Smaller, Normal, or Larger).
- **Red Shade Accent Update**: Corrected the app's neon red shade to use exactly `#ff0000`.

## 🌟 Version 1.1.4 Highlights

- **Dynamic Resizing on Linux & Windows**: Added window resizing capability from the corners while enforcing a strict `9:16` aspect ratio, making the desktop view match standard mobile proportions.
- **Fixed Layout Overflow**: Wrapped AppBar components in FittedBox scaling to automatically scale down the app title and stable badge when resized to narrow resolutions.
- **Google Fonts Integration**: Migrated typography to use free, open-source Google Fonts via the `google_fonts` package, allowing dynamic font configuration and removing local custom font assets from the bundle.
- **Cleaned Boilerplate Residues**: Verified package identifiers across Android, Linux, Windows, and Web platforms to ensure no `com.example` or legacy names remain.

## 🌟 Version 1.1.3 Highlights

- **Rebranded to GATEletics:** Complete application rename from GATE Tracker to GATEletics across all documentation, source code, build scripts, database files, and platform packaging structures.
- **Updated Package ID:** Relocated Android packaging namespace to `com.vishnunandan.gateletics` to align with the new application branding.

## 🌟 Version 1.1.2 Highlights

- **Legal Agreement Onboarding Screen:** Added a compliance welcome screen prompting users to read and accept the Terms of Service and Privacy Policy before accessing the app.
- **Onboarding Setup Flow:** Introduced an interactive setup flow helping users choose between Syllabus-Based and Resource-Based tracking, and whether to load our presets or build a custom setup from scratch.
- **Simplified Empty States:** Streamlined the dashboard's empty states to display a clean, single-action button ("Create Category") after setup.
- **Polished About Dialog:** Beautifully redesigned the About dialog, including a customized neon GitHub button matching the theme, and adjusted button scaling across standard resolutions.

---

## 🌟 Version 1.1.1 Highlights

- **Unified Welcome Screen:** Replaced duplicate onboarding flows with a single, modern welcome screen that offers immediate toggle switching between Resource-Based and Syllabus-Based completion modes.
- **Smart Custom Syllabus Warning:** Added a confirmation dialog when creating a custom category in Syllabus-Based mode, warning users about the tedious manual setup process and highly recommending the predefined presets instead.
- **Complete Reset Everything:** The "Reset Everything" option in Settings now wipes tracking data across both databases completely, restoring the app to the initial welcome state regardless of the current mode.
- **Dynamic Motivational Quotes:** Tap the app title logo in the dashboard to reveal a random motivational quote in a beautiful animated dialog. Quotes are fetched from a live `quotes.json` file in the repository and cached locally for offline access — no app update needed to add new ones.
- **Community Quote Contributions:** Users can contribute motivational quotes by submitting a Pull Request to update `quotes.json`. See [CONTRIBUTING.md](CONTRIBUTING.md) for a step-by-step guide.
- **Refreshed App Icon:** New neon cyan-to-blue gradient G logo across all platforms — Android (all densities), Web (favicon + PWA icons), Windows (.ico), and Linux (AppImage).
- **Slow Download Fallback:** During an in-app update download on Android, a new "Download in Browser Instead" button lets users open the direct APK download link in their browser as a reliable fallback if the in-app download is slow.

---

## 📂 Codebase Structure

```text
.
├── android/          # Android platform configuration & packaging
├── fonts/            # Curated typography assets (Outfit, BatmanForever, etc.)
├── lib/
│   ├── core/         # Routing schema and premium UI theme variables
│   ├── database/     # Drift SQL schema definitions and generated tables
│   ├── features/     # Feature-focused modules (Dashboard, Subject Detail, Presets)
│   ├── providers/    # Riverpod controllers, notifier providers, update checks
│   └── widgets/      # Reusable components (Backup, settings sheet, about card)
├── linux/            # Linux platform builds and shell targets
├── test/             # Comprehensive unit testing suite (updater, DB operations)
├── web/              # Web platform support assets (includes local WebAssembly sql-wasm files)
└── windows/          # Windows platform runner targets and window setups
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the file for details.
