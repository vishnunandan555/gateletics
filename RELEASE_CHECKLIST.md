# Pending Release Checklist — GATEletics

This checklist tracks the remaining technical and submission steps required to publish the production web and Android builds.

---

## 🔑 1. Production OAuth & Google Sign-In Setup
- [ ] **Web Domains Whitelisting:**
  - Add production Vercel/GitHub Pages domains to **Authentication > Settings > Authorized domains** in Firebase Console.
- [ ] **Google Cloud API Credentials:**
  - Add production domain to **Authorized JavaScript origins** in Google Cloud Console.
  - Verify redirect URI (`https://<project-id>.firebaseapp.com/__/auth/handler`).
- [ ] **Release SHA Fingerprints:**
  - Retrieve SHA-1 and SHA-256 certificate fingerprints from Google Play Console **Setup > App integrity** (for Google Play builds).
  - Retrieve SHA-1 and SHA-256 from local release keystore via `keytool` (for direct release APKs).
  - Add both sets of fingerprints to **Project settings > Android app** in Firebase Console.
- [ ] **Config Update:**
  - Download the updated `google-services.json` from Firebase Console and replace the old one at `android/app/google-services.json`.

---

## 📦 2. Production Signing & Android Builds
- [ ] **Keystore Generation:**
  - Run `keytool -genkey -v -keystore android/app/release.jks ...` to create the signing key.
- [ ] **Signing Configurations:**
  - Create local `android/key.properties` with keystore passwords and alias.
- [ ] **Obfuscated App Bundle:**
  - Run `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info`.

---

## 📋 3. Google Play Store Submission
- [ ] **Legal URL:**
  - Paste hosted Privacy Policy URL (`docs/PRIVACY_POLICY.md` on GitHub Pages) into Play Console.
- [ ] **Graphic Assets:**
  - Upload 1024×500 feature graphic.
  - Upload dashboard & checklist screenshots.
- [ ] **Data Safety Declarations:**
  - Declare "No" to data collection (since the database is local/offline, except for user-initiated Firebase backups).
- [ ] **Closed Testing track:**
  - Recruit 20 active testers and complete the mandatory 14-day testing period.