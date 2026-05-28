# GATE Progress Tracker

[![Build & Release](https://github.com/vishnunandan555/gate-tracker/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/vishnunandan555/gate-tracker/actions/workflows/release.yml)
[![Version](https://img.shields.io/badge/version-1.0.0--stable-emerald.svg)](https://github.com/vishnunandan555/gate-tracker/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

A minimalist, high-performance, offline-first syllabus tracker designed specifically for the Graduate Aptitude Test in Engineering (GATE) Exam. It enables aspirants to logically organize subjects, define syllabus weights, and track video-course or syllabus completion progress.

---

## 🛠️ Architecture & Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart SDK `^3.12.0`)
- **State Management:** [Riverpod](https://riverpod.dev) (Modern, type-safe reactive state tracking)
- **Database Engine:** [Drift](https://drift.simonbinder.eu) (Robust, compile-safe relational SQLite wrapper)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (Declarative routing)

---

## 📂 Local Data Storage Specifications

GATE Progress Tracker is fully offline-first, requiring no network connection to operate. All database instances, progress entries, and custom configurations are stored locally on the host device.

| Platform | Database Type | Storage Directory / File Path | Permission Prompts |
| :--- | :--- | :--- | :--- |
| **Android** | SQLite | `/data/data/com.example.gate_tracker/app_flutter/gate_tracker.db` | None (App-private storage) |
| **Linux** | SQLite | `~/Documents/gate_tracker/gate_tracker.db` | None (User directory) |
| **Windows** | SQLite | `C:\Users\<username>\Documents\gate_tracker\gate_tracker.db` | None (User directory) |
| **Web** | IndexedDB | Browser-managed client-side database storage | None (Standard HTML5 storage) |

### Note on Web Storage (IndexedDB)
* In modern web browsers, IndexedDB operates silently out-of-the-box.
* **No explicit permission prompt** is requested or required, making the user experience frictionless.
* Data is persisted per website origin (Same-Origin Policy).
* *Caveat:* If the host system runs critically low on disk space, or if the user is in certain restrictive Private/Incognito browser sessions, the browser may treat the storage as temporary or clear it upon closing the tab.

---

## ✨ Features

- **Progress Analytics:** overall exam completion index visualized using a high-fidelity animated progress ring.
- **Relational Structure:** Subjects are dynamically assigned to parent Categories (Syllabus Areas) with progress rolling up automatically.
- **Customizable Subjects:** Tap-to-edit video syllabus counts, customized source channels, and direct course/playlist URLs.
- **Pre-configured Presets:** Instantly bootstrap your tracking with complete syllabus and video count presets (e.g., GoClasses/YouTube).
- **JSON Import/Export:** Secure backup utility that lets you export or import your progress as a relational JSON schema, facilitating backup portability.
- **Automatic Self-Updater:** Fully integrated GitHub Releases check that notifies you of newer versions and facilitates direct asset downloads on supported native targets.

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

To build a release binary (e.g., for Linux):
```bash
flutter build linux
```

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
│   └── widgets/      # Reusable components (Backup & settings sheets, about card)
├── linux/            # Linux platform builds and shell targets
├── test/             # Comprehensive unit testing suite (updater, DB operations)
└── windows/          # Windows platform runner targets and window setups
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the file for details.
