# 🏁 GATE Progress Tracker

A sleek, premium, dark-themed offline preparation progress tracker built using **Flutter** and **Isar Database**. Designed specifically for GATE (Graduate Aptitude Test in Engineering) aspirants to organize, track, and visualize their video course progress across all core Computer Science subjects.

---

## ✨ Features

- **📊 Dynamic Dashboard:** Sleek progress squircle with overall completion percentage (accurate to two decimal places).
- **🎨 Rich Modern Aesthetics:** harmonized dark mode palette (`zinc` and custom high-contrast neon accents) with subtle glassmorphic elements.
- **⚡ Tactile Physics-Based Micro-Animations:** Minor scale-down micro-animations (`0.92` scale on press over `100ms` using `Curves.easeOutCubic`) on counter adjustments and link tags for a highly responsive, physical feel.
- **📦 Zero-Permission Backup System:**
  - **Export:** Saves backup `.json` locally to your device via the native system document manager (SAF) using zero-permission scoped storage.
  - **Import:** Restores database records securely from a `.json` backup file.
- **🔗 Direct Subject Playlist Redirection:** Seamlessly launch video playlist URLs directly on mobile devices with verified Android package-visibility query intents.
- **💾 Embedded Offline Storage:** High-performance local storage powered by **Isar Community Database**.

---

## 🛠️ Technology Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart)
- **State Management:** [Riverpod](https://pub.dev/packages/flutter_riverpod)
- **Database:** [Isar Community](https://pub.dev/packages/isar_community)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Platform Utils:** `file_picker`, `url_launcher`

---

## 🚀 Getting Started

### 📋 Prerequisites
- Flutter SDK (3.19.0 or higher recommended)
- Android Studio / VS Code
- Android Device / Emulator

### 🔧 Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd GATE
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

## 💾 Local Backup Format

Backups are exported in a standard `.json` format:
```json
[
  {
    "name": "Engineering Mathematics",
    "completedVideos": 15
  },
  {
    "name": "Discrete Mathematics",
    "completedVideos": 24
  }
]
```

---

## 🤝 Contribution

Contributions are welcome! Please open an issue or submit a pull request if you would like to help improve the tracker.
