# Google Play Store Release Checklist — GATE Progress Tracker

> **Why now?** Android is progressively restricting sideloading (unknown source installs). Getting on the Play Store is the correct long-term solution for reliable distribution.

---

## ⚡ TL;DR — Quick Status at a Glance

### 🚫 Hard Blockers & Must-Declares — ALL RESOLVED & CLEANED ✅

All telemetry, self-updating APK systems, and sensitive permissions have been fully removed from the codebase. The app is now clean and compliant with Google Play Developer policies.

| # | Prior Issue | Status | Action Taken |
|---|---|---|---|
| 1 | **In-app APK downloader** | ✅ **RESOLVED** | Removed entire download flow, updater provider, updater dialog, and unreferenced packages. |
| 2 | **`REQUEST_INSTALL_PACKAGES` permission** | ✅ **RESOLVED** | Removed the permission from `AndroidManifest.xml`. |
| 3 | **`requestLegacyExternalStorage="true"`** | ✅ **RESOLVED** | Removed the legacy attribute from `AndroidManifest.xml`. |
| 4 | **Telemetry pings & endpoints** | ✅ **RESOLVED** | Deleted the telemetry service, lifecycle observer, and settings toggles. The app is now 100% offline. |
| 5 | **Debug mock constants** | ✅ **RESOLVED** | Cleaned up all developer mock constants and versions from the updater/telemetry stubs. |

---

## 📋 Build & Submit Checklist

### 1. Release Keystore & App Signing
Since you have not started the Google Developer account yet, you can configure signing configurations once you are ready. Below is the step-by-step setup:

1. **Generate the Keystore:**
   Run this command in your terminal to generate a secure keystore file:
   ```bash
   keytool -genkey -v -keystore android/app/release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```
2. **Configure Credentials:**
   Create a file at `android/key.properties` (this file is ignored by git to keep secrets safe) containing:
   ```properties
   storePassword=<your-keystore-password>
   keyPassword=<your-key-password>
   keyAlias=key
   storeFile=release.jks
   ```
3. **Build the Production Bundle:**
   Once signing is wired up in `build.gradle.kts`, run this command to build the optimized App Bundle (AAB):
   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
   ```

---

## 📄 2. Legal Requirements (ToS & Privacy Policy)

To publish on the Google Play Store, Google **requires** a Privacy Policy URL. A Terms of Service (ToS) is optional but highly recommended to limit your liability.

### Checklist & Action Items:
- [x] Create `PRIVACY_POLICY.md` in repository root (Completed ✅)
- [x] Create `TERMS_OF_SERVICE.md` in repository root (Completed ✅)
- [x] Integrate first-launch Legal Agreement Screen to lock the app until agreed (Completed ✅)
- [x] Integrate Onboarding Setup Screen for style & preset selection (Completed ✅)
- [x] Push changes to GitHub repository (Completed ✅)
- [x] Host the files on the web (Created `/docs` files for GitHub Pages ✅)
- [ ] Paste hosted Privacy Policy link into Google Play Console (Console app not created yet - pending ⏳)

---


### 3. Store Assets & Submissions (For Later)
- **Feature Graphic:** 1024×500 PNG/JPEG (no transparent background).
- **Screenshots:** At least 2 screenshots showing the main tracking dashboard and syllabus checklist.
- **Data Safety Form (Play Console):**
  - Select **"No"** to *Does your app collect or share any of the required user data types?*
  - This matches our clean, 100% offline codebase.
- **Closed Testing Requirement:** For personal developer accounts created after November 2023, Google requires a 14-day closed testing track with at least 20 testers before publishing to Production. Planning this early is highly recommended.