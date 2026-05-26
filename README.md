# 🏁 GATE Progress Tracker `v0.0.3`

A sleek, premium, dark-themed offline preparation progress tracker built using **Flutter** and **Isar Database**. Designed specifically for GATE (Graduate Aptitude Test in Engineering) aspirants to organize, track, and visualize their video course progress across all core Computer Science subjects.

---

## ✨ Features

- **📊 Dynamic Dashboard:** Sleek progress squircle with overall completion percentage tracking active subjects.
- **🛠️ Subject Presets:** Instantly apply course metadata (GoClasses/YouTube) for standard GATE subjects with one click.
- **🎨 Modern Alpha UI:** Adaptive scaling, premium zinc-palette dark mode, and glassmorphic elements.
- **⚡ Tactile UX:** Physics-based micro-animations on all interactive elements.
- **📦 Full Metadata Backups:**
  - **Export/Import:** Now supports full synchronization of sources, course links, progress, and active status.
- **🔗 Smart URL Handling:** Automatic `https://` detection and native app redirection (YouTube/Browsers).
- **💾 Embedded Offline Storage:** High-performance local storage powered by **Isar Community Database**.

---

## 🛠️ Technology Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart)
- **State Management:** [Riverpod](https://pub.dev/packages/flutter_riverpod)
- **Database:** [Isar Community](https://pub.dev/packages/isar_community)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Platform Utils:** `file_picker`, `url_launcher`, `share_plus`

---

## 🚀 Getting Started

### 📋 Prerequisites
- Flutter SDK (3.11.0 or higher)
- Android Studio / VS Code
- Linux/Windows/Android environment

### 🔧 Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd gate-tracker
   ```

2. **Get packages:**
   ```bash
   flutter pub get
   ```

3. **Generate Isar schemas:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── router/          # App navigation (GoRouter)
│   └── theme/           # Premium dark theme styling
├── database/
│   ├── models/          # Isar Schema models (Subject, etc.)
│   └── isar_service.dart # Local database services
├── features/
│   └── dashboard/       # Dashboard & Settings UI
├── providers/           # Riverpod state providers
└── widgets/             # Reusable animated UI elements
```

---

## 💾 Local Backup Format (v0.0.3)

Backups now capture the full application state:
```json
[
  {
    "name": "Engineering Mathematics",
    "category": "Mathematical Foundation",
    "completedVideos": 15,
    "totalVideos": 111,
    "playlistLink": "https://...",
    "sourceName": "GoClasses",
    "isActive": true
  }
]
```

---

## 🤝 Contribution

Contributions are welcome! Please open an issue or submit a pull request if you would like to help improve the tracker.
