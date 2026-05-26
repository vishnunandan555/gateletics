# 🏁 GATE Progress Tracker

[![Build & Release App](https://github.com/vishnunandan555/gate-tracker/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/vishnunandan555/gate-tracker/actions/workflows/release.yml)
[![Version](https://img.shields.io/badge/version-0.0.3-blue.svg)](https://github.com/vishnunandan555/gate-tracker/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

A simple tool to track your GATE exam preparation progress.

Note: This project is in prerelease. Make sure to back up your data.

---

## ✨ Features

- **Dashboard:** View overall completion.
- **Progress Tracking:** Track video course status.
- **Subject Presets:** Add standard subjects easily.
- **Dark Mode:** Easy on the eyes.
- **Backups:** Export and import as JSON.
- **Course Links:** Open videos directly.
- **Offline:** Data stays on your device.

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
   flutter pub get
   ```

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
