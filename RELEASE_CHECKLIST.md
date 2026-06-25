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
- [ ] Push changes to GitHub repository
- [ ] Host the files on the web (e.g. enable GitHub Pages for the repository)
- [ ] Paste the hosted Privacy Policy link into the Google Play Console

### How to Host These Files for Free
1. **GitHub Pages (Recommended):**
   - Enable GitHub Pages on your `gateletics` repo in **Settings -> Pages**.
   - Use the URL (e.g., `https://vishnunandan555.github.io/gateletics/PRIVACY_POLICY.md`) in your Play Console submission.

### Copy-Paste Templates

Below are complete, tailored templates you can use for this app:

````carousel
```markdown
# Privacy Policy for GATEletics

Last updated: June 25, 2026

Vishnu Nandan ("we", "our", or "us") operates the GATEletics mobile application (the "App"). We are committed to protecting your privacy. This Privacy Policy explains our practices regarding your information.

## 1. Information Collection and Use

**No Personal Information Collected:** 
The App is designed as an offline-first tool. We do not collect, store, or transmit any personally identifiable information (PII) or user tracking data. 

**Local Storage:**
All study progress, syllabus checklists, subjects, and tracking data are stored locally on your device's secure storage using an embedded database. This data never leaves your device unless you manually choose to export it to a JSON backup file.

**Internet Access:**
The App requires internet access (`android.permission.INTERNET`) solely to fetch daily motivational quotes from a public repository. No user-specific identifier, location, or device telemetry is transmitted during this fetch.

## 2. Third-Party Services
The App does not use any third-party analytics, advertising networks, or tracking SDKs.

## 3. Children's Privacy
Our App does not collect any information from children or anyone else, making it fully compliant with COPPA and global privacy standards.

## 4. Contact Us
If you have any questions about this Privacy Policy, please contact us at: vishnunandan555@gmail.com
```
<!-- slide -->
```markdown
# Terms of Service for GATEletics

Last updated: June 25, 2026

Please read these Terms of Service ("Terms") carefully before using the GATEletics mobile application (the "App") operated by Vishnu Nandan ("us", "we", or "our").

## 1. Acceptance of Terms
By downloading or using the App, you agree to be bound by these Terms. If you disagree with any part of the terms, you may not access or use the App.

## 2. License to Use
We grant you a personal, non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial educational purposes on devices owned or controlled by you.

## 3. Intellectual Property
The App, its original features, and source code are open-source and licensed under the MIT License. You may modify and redistribute it under the terms of the MIT License, but the official Play Store version and brand name "GATEletics" are represented by the developer.

## 4. Limitation of Liability & "As-Is" Clause
The App is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, either express or implied. 

In no event shall Vishnu Nandan be liable for any direct, indirect, incidental, special, or consequential damages arising out of your use of, or inability to use, the App. This includes, but is not limited to, loss of study data, device issues, or errors in syllabus descriptions.

## 5. Changes to Terms
We reserve the right to modify or replace these Terms at any time. Your continued use of the App after changes constitutes acceptance of the new Terms.

## 6. Contact Us
For any questions regarding these Terms, contact: vishnunandan555@gmail.com
```
````

---

### 3. Store Assets & Submissions (For Later)
- **Feature Graphic:** 1024×500 PNG/JPEG (no transparent background).
- **Screenshots:** At least 2 screenshots showing the main tracking dashboard and syllabus checklist.
- **Data Safety Form (Play Console):**
  - Select **"No"** to *Does your app collect or share any of the required user data types?*
  - This matches our clean, 100% offline codebase.
- **Closed Testing Requirement:** For personal developer accounts created after November 2023, Google requires a 14-day closed testing track with at least 20 testers before publishing to Production. Planning this early is highly recommended.