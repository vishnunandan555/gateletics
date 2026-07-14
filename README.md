# GATEletics

[![Build & Release](https://github.com/vishnunandan555/gateletics/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/vishnunandan555/gateletics/actions/workflows/release.yml)
[![Version](https://img.shields.io/badge/version-1.2.12-emerald.svg)](https://github.com/vishnunandan555/gateletics/releases)
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

- **Unified Home Dashboard:** A premium landing screen featuring a real-time `DAYS : HRS : MINS : SECS` countdown to the GATE exam, a motivational launch quote, a syllabus completion card, a 7-day consistency grid, and an animated "Resume Preparation" button that tracks daily goal progress.
- **Setup Wizard & Multi-Branch Onboarding:** A 6-card setup wizard (Profile → Daily Goal → Exam Date → Branch → Tracking Slate → Review) runs on first launch or can be re-run from Settings. Supports all 7 GATE branches: CS, DA, EC, EE, CE, ME, CH.
- **Progress Analytics:** Overall exam completion index visualized using a high-fidelity animated progress ring.
- **Relational Structure:** Subjects are dynamically assigned to parent Categories (Syllabus Areas) with progress rolling up automatically.
- **Customizable Subjects:** Tap-to-edit video syllabus counts, customized source channels, and direct course/playlist URLs.
- **Pre-configured Presets:** Instantly bootstrap your tracking with complete syllabus presets for every GATE branch.
- **Study Focus Mode (Pomodoro & Ultradian):** A dedicated productivity workspace with configurable focus timers and daily goal tracking. Sessions are permanently saved to the local database.
- **JSON Import/Export:** Secure backup utility that lets you export or import your progress as a relational JSON schema, facilitating backup portability.
- **Firebase Authentication & Cloud Sync:** Sign in with Google to enable automatic, offline-first progress backups with intelligent merge conflict resolution and soft-delete support.
- **Premium Customization System:**
  - Profile customization (display name, photo mode, photo size).
  - 7 premium progress fonts (Orbitron, Jersey 15, Jersey 10, Tektur, OdibeeSans, PressStart2P, Boldonse).
  - Animated home screen glow, focus animation styles (Wave/Ripple), and Resume button fill styles.
  - Per-element font size controls (Category headers, Syllabus Topics, Syllabus Tasks) and a global UI scale.
- **Advanced & Beta Settings:** Collapsible "Advanced Options" (glow intensity, avatar size, disable countdown, disable home widgets, disable chart glow) and "Beta" panel (projected completion, inject mock session) under a single ADVANCED section.
- **Cross-Platform Promo Banner (Web):** A subtle informational card in Settings for web users promoting the native Android, Windows, and Linux versions, with a toggle to dismiss it permanently.

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

## 📦 Compiled Releases & Artifact Naming

All production releases are automatically compiled, versioned, and packaged via GitHub Actions CI/CD on tag pushes. The following files are attached to each release in the exact order below:

1. **Web App Archive** (`gateletics-web-v1.x.x.zip`): Deployable static web assets.
2. **Android App Bundle** (`gateletics-v1.x.x.aab`): Production bundle for Google Play Store.
3. **Android APK** (`gateletics-v1.x.x.apk`): Direct standalone mobile installer.
4. **Windows (Mobile UI)** (`gateletics-windows-mobileUI-v1.x.x.zip`): Desktop port with mobile-ratio locked layout.
5. **Linux (Mobile UI - AppImage)** (`gateletics-linux-mobileUI-v1.x.x.AppImage`): Portable Linux binary with mobile-ratio locked layout.
6. **Linux (Mobile UI - Tarball)** (`gateletics-linux-mobileUI-v1.x.x.tar.gz`): Compressed Linux files with mobile-ratio locked layout.
7. **Windows (Desktop UI)** (`gateletics-windows-deskUI-beta-v1.x.x.zip`): Optimized widescreen grid layout (BETA).
8. **Linux (Desktop UI - AppImage)** (`gateletics-linux-deskUI-beta-v1.x.x.AppImage`): Portable widescreen Linux binary (BETA).
9. **Linux (Desktop UI - Tarball)** (`gateletics-linux-deskUI-beta-v1.x.x.tar.gz`): Compressed widescreen Linux files (BETA).

## 🌟 Version 1.2.10 Highlights

- **Fixed Completion Screen Glitching & Reloading**: Wrapped syllabus progress updates inside atomic database transactions so that multiple database writes update stream queries exactly once, preventing double UI refreshes.
- **Fixed Subject Cards Auto-Collapse**: Included the `hideDownloadBanner` preference property directly inside `exportLocalData()` and merged data outputs to prevent false negatives in the data equality comparison. This eliminates unintended local database restores that were resetting the expanded card caches on every subtask toggle.
- **Robust Local Database Restores**: Removed manual cache clearing from the background sync restore method. Sync updates will now silently populate in the background without collapsing user's open topic/subject panels.

## 🌟 Version 1.2.9 Highlights

- **Auto-Sort and Navigation Fixes**: Cleared locked category sorting order when switching tabs, so that returning to the Completion page re-sorts categories correctly by recent interaction.
- **Subject Cards Collapse Fix**: Optimized data sync logic to avoid local database restores when no remote updates are found. This prevents expanded subject cards from collapsing on subtask click.
- **Complete Reinstall Reset**: Updated the "Reset Everything" feature to completely sign out Firebase and Google Sign-in, clear all local database tables (syllabus tasks, custom tasks, focus sessions, daily history), and purge SharedPreferences to simulate a fresh reinstall.
- **Improved Reset Tracking Data**: "Reset Tracking Data" now completely purges all focus sessions, daily history, and custom tasks, and resets syllabus tasks completions to false and completedAt timestamps to null.
- **Delete Account Warning**: Added a compliant "local data still exists" warning dialog after server-side deletion, which signs out the user locally on OK press and returns them to the auth screen.
- **UI Tweaks**: Changed statistics timeframe labels to grammatical nouns (week, month, year) and redesigned the update notification SnackBar to align text and actions side-by-side in a single row.

## 🌟 Version 1.2.8 Highlights

- **Results-Based Category Progress (DB Version 10)**: Added `completedAt` timestamp to task completions. Syllabus-based progress tracking calculates Focus Area Distribution percentages dynamically from completed tasks in a chosen timeframe (Weekly/Monthly/Yearly) instead of manually tagging active timers.
- **Focus Setup UI & Layout Improvements**: Cleaned up manual category dropdowns. Standardized the setup view height to a fixed `252` pixels (responsive-scaled) to prevent UI jumping when switching modes. Adjusted Focus/Resume buttons to use clean 12px rounded corners.
- **Notice Board Badges**: Added a solid green task counter badge next to the Notice Board toggle icon on both desktop and mobile layouts when the list contains tasks. Icons dynamically scale to 32px when the badge is present.
- **Storage Compaction**: Implemented automatic cleanups that wipe detailed raw focus session entries older than the current day on rollover, keeping the local DB and Drive sync payload ultra-lightweight.
- **Calendar Layout Stability**: Forced the calendar grid to always render exactly 6 rows (42 cells) to stop height shifts and UI blinking when switching months.

## 🌟 Version 1.2.7 Highlights

- **Unified Home Dashboard:** Introduced a new premium home screen as the app's entry point. Features a ticking real-time GATE countdown, a dynamic launch quote, an overall completion card, an animated "Resume / Start Preparation" button with three fill style modes, and a 7-day horizontal consistency grid showing daily focus goal progress.
- **Active Focus Wave Indicator:** When a focus session is actively running, the Resume button on the home screen morphs into an animated wave/ripple indicator that navigates directly to the Focus tab on tap.
- **Profile Customization System:** New profile settings letting users set a custom display name, choose between Google photo/custom photo/initials avatar, and configure the avatar size.
- **Glow Strength & Animation Settings:** Added sliders and toggles for the home screen radial glow intensity and the focus animation style (Wave vs. Ripple).
- **Resume Button Fill Style:** Three new button fill styles (Rectangular Fill, Neon Gradient, Bottom Micro Indicator) to personalize the home screen's call-to-action button.
- **Font Size Granularity:** Separate font size controls for Syllabus Topics and Syllabus Tasks, in addition to the existing Category font size setting.
- **Overall UI Scale Control:** A global text scale factor setting in Advanced Options affecting the entire application.
- **Cross-Platform Download Banner:** Added an informational banner in Cloud Sync settings (web only) promoting native apps, with a cloud-synced "Hide Promo" toggle in Advanced Options.

## 🌟 Version 1.2.5 Highlights

- **Interactive Study Focus Mode**: Added a dedicated productivity workspace with support for Pomodoro and Freestyle timers to track study sessions.
- **Dynamic Daily Goals**: Integrated visual goal widgets displaying study metrics (completed/remaining hours, percent progress) with interactive cycling.
- **Account Deletion Flow**: Added a compliant account deletion request flow inside the settings interface to adhere to app store policies.
- **Persistent Desktop UI Prefs**: Support for remembering user UI preferences (desktop vs. mobile view mode) and automated layout detection.
- **Sync Stabilization**: Fixed continuous sync loops on conflict resolutions and corrected mode reset bugs.

## 🌟 Version 1.2.4 Highlights

- **Completion-Type Tuning**: Changed default completion tracking strategy to syllabus-based.
- **Robust Version Updates**: Added direct, automated app update checks and native release notifications.
- **Enhanced Sync Settings**: Deeper sync frequency configs integrated cleanly within the settings view.
- **Desktop Warning Optimization**: Automatically checks viewport width and notifies users when resizing will optimize the presentation.

## 🌟 Version 1.2.3 Highlights

- **Dynamic Widescreen Desktop UI**: Bypassed strict `9:16` aspect ratio constraints when run under the `FORCE_DESK_UI` environment. Enabled clean, resizable window configurations starting at `1280x720` for Linux and Windows runner targets.
- **Desktop UI Auto-Routing**: Mapped initial route resolver in Riverpod router to directly bootstrap into `/desk` layouts on native platforms when desktop mode is active.
- **Sidebar Overflow Patches**: Fixed font and padding layout scaling inside `desk_dashboard_shell.dart` to prevent visual `RenderFlex` exceptions.
- **Robust Clean Reboots**: Enhanced settings "Reset Everything" mechanism to purge all `SharedPreferences` onboarding keys, ensuring database reset properly triggers the legal agreement welcome flow.
- **CI/CD Workflow Improvements**: Configured automated compilation environments for desktop-ratio builds, outputting dual-UI desktop binaries.
- **Landing Page Polish**: Added platform logos to download columns (Windows, Linux, Android) with responsive dark/light styling, and added an auto-updating "What's New" container pulling release notes directly from the GitHub API.

## 🌟 Version 1.2.2 Highlights

- **Web Compatibility & Google Login Fixes**: Replaced the deprecated and cookie-blocked `google_sign_in_web` package flow on Web targets with Firebase Auth's native `signInWithPopup`, resolving critical cross-origin iframe security issues and `popup_closed` errors on non-Chrome browsers (like Firefox and Safari).
- **Responsive Desktop Warn Banner**: Added checks to automatically detect wide desktop screen viewports on Web and display a friendly, user-dismissible onboarding dialog recommending mobile aspect ratio sizing.
- **Advanced Sync Frequencies**: Added settings for background synchronization intervals (Instant, Every 5 Minutes, On App Close, and Manual) nested inside a collapsed-by-default ExpansionTile.
- **Optimized Lifecycle Syncing**: Background sync listener flushes unsaved local database changes to the cloud automatically when the app is minimized, closed, or suspended on mobile platforms.
- **Improved Conflict Resolutions**: Integrated a structural check `_areDataEqual` to perform deep comparison of local and backup database stats. It exits early on equality to prevent duplicate prompt popups if local data matches the cloud backup, and visualizes the cloud's last synced time in the conflict modal.
- **Robust Database Restoration**: Clears stale Riverpod cached notifier IDs upon database restore or JSON import to avoid UI-query mismatches, and forces server-side Firestore calls for data validation.

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
- **Fixed Layout Overflow**: Wrapped AppBar components in FittedBox scaling to automatically scale down the app title and beta badge when resized to narrow resolutions.
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
