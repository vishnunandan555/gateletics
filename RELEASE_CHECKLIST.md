# Google Play Store Release Checklist — GATEletics

This document provides a comprehensive, step-by-step checklist to prepare, build, sign, and successfully publish GATEletics to the Google Play Store and web hosted environments (Vercel) without policy rejections or technical issues.

---

## 🔑 1. Developer Account & Initial Settings
- [x] **Google Play Developer Account Verification:**
  - Complete identity verification with government ID (and D-U-N-S business registry if registering under an Organization account).
  - Ensure 2-Factor Authentication (2FA) is turned on for the developer Google account.
- [x] **Data Safety Declarations (Google Play Console):**
  - **No Ads:** Declare that the app does not contain ads. ✅ Done.
  - **No Restricted Content:** Completed the news, government app, and financial features declarations (marked "No" to all). ✅ Done.
  - **Advertising ID:** Declared that the app does NOT use advertising ID. ✅ Done.
  - **Data Safety Form:** 
    - Declared that user authentication credentials (email/name) are collected for account creation/auth when using Google Sign-In.
    - Declared that database sync backups (syllabus checklist & focus sessions) are collected/stored.
    - Clarified that all transmission is securely encrypted in transit (HTTPS) and that users can request permanent deletion of their account & data (in compliance with the new Account Deletion rules).

---

## 🧪 2. Mandatory 14-Day Closed Testing Track (Personal Accounts)
If your personal developer account was created after **November 13, 2023**, Google Play requires running a closed test before you can release to production:
- [ ] **Recruit Testers:**
  - Recruit at least **12 unique, opted-in testers**.
  - **Important:** Testers must be real users on real Android devices (emulators, simulator tools, or duplicate bot accounts will not qualify and will result in production access request rejections).
- [ ] **Closed Testing Setup:**
  - Create a **Closed Testing** track release in Google Play Console (do not use Internal Testing, as it does not count toward the requirement).
  - Add your 12 testers' Google email addresses to the testing list.
  - Share the opt-in web link (provided by the Play Console) with your testers.
- [ ] **14-Day Consecutive Run:**
  - Ensure all 12 testers opt in, install the app, and keep it installed for **14 consecutive days**.
  - **Warning:** If your active opted-in tester count drops below 12 during these 14 days, the clock will reset. Keep in touch with your testers to ensure they don't uninstall or opt out.

---

## 🌐 3. Firebase & Google OAuth Console Configuration
To prevent Google Sign-In failures in production (such as the standard `DEVELOPER_ERROR` or popup blockages), you must configure authorized domains and SHA credentials:

### A. Web Hosted App (Vercel / GitHub Pages)
- [x] **Firebase Authorized Domains:**
  - Open [Firebase Console](https://console.firebase.google.com/) > **Authentication** > **Settings** > **Authorized domains**.
  - Click **Add domain** and enter your production web domain (e.g. `gate-tracker.vercel.app`).
- [x] **Google Cloud Console Redirects:**
  - Open [Google Cloud Console Credentials](https://console.cloud.google.com/apis/credentials).
  - Select your **OAuth 2.0 Client ID** for the Web application.
  - Add your production URL to **Authorized JavaScript origins**.
  - Add the Firebase Auth handler URL (e.g., `https://<your-project-id>.firebaseapp.com/__/auth/handler`) to **Authorized redirect URIs**.

### B. Android App (Google Play Console & Firebase)
- [x] **Create App in Google Play Console:**
  - Create a new app project in Google Play Console (Personal/Business Developer Account).
  - Register the package name: `com.vishnunandan.gateletics`.
- [x] **Register Android App in Firebase Console:**
  - Open Firebase Console, select your project, and click **Add App** > **Android**.
  - Enter the Android package name: `com.vishnunandan.gateletics`.
  - Enter an app nickname (optional: e.g., "GATEletics Android").
- [x] **Add App Signing Key SHA Fingerprints:**
  - When you upload your AAB, Google Play signs your production app with a master key.
  - Go to your Google Play Console > select your app > **Setup** > **App integrity** > **App signing** tab.
  - Copy both the **SHA-1** and **SHA-256** certificate fingerprints.
  - Go to your Firebase Console > **Project settings** > **Your apps** > **Android app** (`com.vishnunandan.gateletics`).
  - Click **Add fingerprint** and paste both SHA-1 and SHA-256 values.
- [x] **Add Local Upload Key SHA Fingerprints:**
  - Follow the steps in Section 4 to create your local upload key.
  - Run the fingerprint extraction command:
    ```bash
    keytool -list -v -keystore android/app/release.jks -alias upload-key
    ```
  - Copy the SHA-1 and SHA-256 fingerprints, go to Firebase Console, and add them to your Android app fingerprints.
- [x] **Replace Configuration File:**
  - Once all fingerprints are added to Firebase Console, download the updated `google-services.json` file.
  - Replace the file at `android/app/google-services.json`.

---

## 📦 4. Android Production Signing Configuration

### Step 1: Generate Keystore
Open a terminal in the root of the project and execute this command to generate your release keystore:
```bash
keytool -genkey -v -keystore android/app/release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload-key
```
*(Keep your keystore password safe and secure. Do not commit `release.jks` to GitHub).*

### Step 2: Configure Properties
Create a local file at `android/key.properties` (which is already added to `.gitignore` to prevent leaking credentials):
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEYSTORE_PASSWORD
keyAlias=upload-key
storeFile=release.jks
```

### Step 3: Configure build.gradle.kts
Ensure your `android/app/build.gradle.kts` configuration is reading the properties correctly and applying the signing configuration to your release build:
```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Obfuscate code
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

---

## 🛠️ 5. Build, Obfuscate & Package
- [ ] **Bump App Version:**
  - Verify that the app version is bumped in `pubspec.yaml` (currently `version: 1.2.5+8`).
- [ ] **Clean Build Cache:**
  ```bash
  flutter clean
  flutter pub get
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- [ ] **Build Obfuscated Android App Bundle (AAB):**
  - Run the compilation script:
    ```bash
    flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
    ```
  - Find the signed bundle at `build/app/outputs/bundle/release/app-release.aab`.

---

## 🎨 6. App Store Listing & Visual Assets
- [ ] **App Icon:**
  - Verify launcher icons are correctly configured using the adaptive format.
- [ ] **Public Privacy Policy:**
  - Verify that the Privacy Policy link is hosted on GitHub Pages:
    `https://vishnunandan555.github.io/gateletics/privacy.html`
  - Paste this exact link into the Google Play Console **App content > Privacy policy** section.
- [ ] **Store Graphics:**
  - **Feature Graphic:** 1024w × 500h pixels PNG or JPEG (no transparency, high visual contrast).
  - **Screenshots:** At least 2-4 screenshots representing core dashboard screens, checklist layouts, and the focus session rings.
- [ ] **Descriptions:**
  - **Short Description:** (Max 80 characters) "A clean tracker and productivity hub for your GATE Exam preparation."
  - **Long Description:** Comprehensive overview outlining subject trackers, syllabus checklist, focus modes (Pomodoro, Ultradian), stats, and cloud sync features.

---

## 🚀 7. Production Release Promotion
- [ ] **Apply for Production Access:**
  - Once your 12 testers have run the app for 14 consecutive days, go to the Google Play Console dashboard.
  - Complete the production access application form (Google will ask a few feedback questions about your testing experience, issues found, and developer responses).
- [ ] **Promote Closed Track to Production:**
  - Once Google approves your production request, go to your **Closed Testing** release.
  - Click **Promote release** and select **Production**.
  - Complete final checks and roll out the release to 100% of users.