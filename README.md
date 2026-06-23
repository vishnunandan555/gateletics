# GATE Progress Tracker

[![Build & Release](https://github.com/vishnunandan555/gate-tracker/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/vishnunandan555/gate-tracker/actions/workflows/release.yml)
[![Version](https://img.shields.io/badge/version-1.1.0--stable-emerald.svg)](https://github.com/vishnunandan555/gate-tracker/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

A minimalist, high-performance, offline-first syllabus tracker designed specifically for the Graduate Aptitude Test in Engineering (GATE) Exam. It enables aspirants to logically organize subjects, define syllabus weights, and track video-course or syllabus completion progress.

---

## 🛠️ Architecture & Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart SDK `^3.12.0`)
- **State Management:** [Riverpod](https://riverpod.dev) (Modern, type-safe reactive state tracking)
- **Database Engine:** [Drift](https://drift.simonbinder.eu) (Robust, compile-safe relational SQLite wrapper)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (Declarative routing)
- **Lifecycle Tracking:** Global `WidgetsBindingObserver` monitoring transitions to automatically trigger daily telemetry date check on app start, resume, and browser tab focus.

---

## 📂 Local Data Storage Specifications

GATE Progress Tracker is fully offline-first, requiring no network connection to operate. All database instances, progress entries, and custom configurations are stored locally on the host device.

| Platform | Database Type | Storage Directory / File Path | Permission Prompts |
| :--- | :--- | :--- | :--- |
| **Android** | SQLite | `/data/data/com.example.gate_tracker/app_flutter/gate_tracker.db` | None (App-private storage) |
| **Linux** | SQLite | `~/Documents/gate_tracker/gate_tracker.db` | None (User directory) |
| **Windows** | SQLite | `C:\Users\<username>\Documents\gate_tracker\gate_tracker.db` | None (User directory) |
| **Web** | IndexedDB | Browser-managed client-side database storage via local WebAssembly | None (Standard HTML5 storage) |

### Note on Web Storage (IndexedDB + WebAssembly)
* **100% Self-Contained Web Target:** To support zero-dependency SQLite connections on Web without slow external CDN dependencies, both `sql-wasm.js` and `sql-wasm.wasm` are stored locally in the `/web` static root.
* **Concurrent Boot Performance:** Preload directives (`<link rel="preload">`) are embedded in the `<head>` of `index.html` to instruct the browser to download WebAssembly assets concurrently, ensuring a super-fast, lag-free boot phase.
* **No explicit permission prompt** is requested or required, making the user experience frictionless.
* Data is persisted per website origin (Same-Origin Policy).

---

## 🔒 Privacy-First Developer Telemetry & Opt-Out

To help the developer track platform metrics and version adoption, an anonymous telemetry ping is evaluated at most once per day on app launch, resume, or tab focus.

- **Zero PII Collected:** No emails, usernames, dynamic database contents, or network details are tracked.
- **Dynamic Daily Hashing:** Pings use a rotating SHA256 daily active user token:
  $$\text{Daily active token} = \text{SHA256}(\text{client\_id} + \text{current\_date\_string})$$
  This token changes automatically every calendar day, preventing longitudinal user tracking or identity linking.
- **Background Deferral Optimization:** The startup telemetry check is deferred until **after the first frame is rendered** (`addPostFrameCallback`), freeing up all CPU and platform-channel bandwidth to paint the UI instantly.
- **Developer Opt-Out Toggle:** A clean, GDPR-compliant toggle along with custom endpoints and connection diagnostics are located under the **Advanced Settings** section in the settings sheet, allowing full user privacy control.

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
  - **Advanced Settings Section:** Grouped advanced diagnostic and telemetry details inside an elegant, borderless `ExpansionTile`.
- **Automatic Self-Updater:** Fully integrated GitHub Releases check that notifies you of newer versions and facilitates direct asset downloads on supported native targets.

## 🌐 Web Deployment (Vercel)

The web target of GATE Progress Tracker is designed for hosting on Vercel:
- **Automated CI/CD Pipeline:** The application uses GitHub Actions to compile Dart code and deploy the pre-built web assets (`/build/web`) to Vercel instantly.
- **Offline PWA Support:** On first load, the browser registers a service worker that caches all application resources—including local SQLite WebAssembly and style binaries—enabling the web app to run 100% offline subsequently.

---

## 🚀 Developer Setup

### Prerequisites
- Flutter SDK `3.44.0` or higher
- Dart SDK `3.12` or higher

### 1. Clone & Fetch Dependencies
```bash
git clone https://github.com/vishnunandan555/gate-tracker.git
cd gate-tracker
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

---

## 🌟 Version 1.1.0 Highlights

- **Syllabus-Based Tracking Mode:** Toggle between video/resource-based tracking and a curriculum-focused syllabus checklist tracking model. Add, rename, delete, and reorder categories, topics, and subtasks.
- **Robust Hybrid Backup Engine:** Modern platform-specific routing using native Kotlin/Swift Storage Access Framework on Android/iOS to bypass Scoped Storage limits, standard web anchor triggers on Web, and native filesystem writes on Desktop.
- **Reordering Scrollbar Fixes:** Added visual scrollbars to all reorder dialogs and fixed touch gesture interferences so that dragging list scrollbars scrolls the view instead of hijacking the item reorder listeners.
- **Cleaned Dashboard UI:** Removed unnecessary long-press logo repository popup menus for a cleaner experience.

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
