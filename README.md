# 🏁 GATE Progress Tracker

[![Build & Release App](https://github.com/vishnunandan555/gate-tracker/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/vishnunandan555/gate-tracker/actions/workflows/release.yml)
[![Version](https://img.shields.io/badge/version-0.0.5--alpha-blue.svg)](https://github.com/vishnunandan555/gate-tracker/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

A simple tool to track your GATE exam preparation progress.

Note: This project is in prerelease (v0.0.5 Alpha). Make sure to back up your data before updating.

---

## ✨ Features

- **Dashboard:** View overall completion with animated progress ring.
- **Progress Tracking:** Track video course completion per subject.
- **Category Progress:** Text-fill header showing per-category completion.
- **Subject Presets:** Apply GoClasses/YouTube defaults in one tap.
- **Self-Updater:** Check for updates from GitHub Releases; download APK directly.
- **Settings Sheet:** Export/import backups, reset data, update frequency, About.
- **Dark Mode:** Easy on the eyes with dynamic accent colours.
- **Backups:** Export and import progress as JSON.
- **Course Links:** Open playlist URLs directly from the app.
- **Offline:** All data stored locally on-device.

---

## 🛠️ Tech Stack

- **Flutter** & **Dart**
- **Riverpod** (State management)
- **Isar** (Local database)
- **GoRouter** (Navigation)

---

## 📥 Download

[Click here](https://github.com/vishnunandan555/gate-tracker/releases) for Android (APK), Windows (ZIP), and Linux (tar and AppImage) downloads.

---

## 🚀 Setup

1. **Clone & Install:**
   ```bash
   git clone https://github.com/vishnunandan555/gate-tracker.git
   cd gate-tracker
   flutter --version
   flutter pub get
   ```

   Requires Flutter 3.44.0+ (Dart 3.12).

2. **Generate Code:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Run:**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```text
.
├── android/    # Android-specific files
├── fonts/      # Custom fonts
├── lib/
│   ├── core/       # Router and Theme
│   ├── database/   # Models and Local DB
│   ├── features/   # UI Screens
│   ├── providers/  # State Logic
│   └── widgets/    # UI Components
├── linux/      # Linux-specific files
├── test/       # Tests
└── windows/    # Windows-specific files
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
