# Comprehensive Android Release Plan for Gate Tracker

This plan provides a first-principles breakdown of everything required to finalize, secure, and release this Flutter application to the Google Play Store. It adheres to strict, brutal validation of constraints: no assumptions, just required steps.

---

## 1. App Finalization & Code Hardening
*Ensure the app works flawlessly and doesn't rely on dev-environment crutches.*

- [ ] **Remove Hardcoded Secrets & Dev Flags:** Ensure no API keys, tokens, or debug flags remain in the source code (especially in `http` usage).
  - *Risk:* Leaking API keys leads to unauthorized usage and financial loss.
  - *Prevention:* Utilize `.env` files (e.g., via `flutter_dotenv`) and CI/CD injection.
- [ ] **Review Permissions (`AndroidManifest.xml`):** Verify that only absolutely necessary permissions are requested. `file_picker`, `share_plus`, and `url_launcher` often require specific intent queries and storage permissions.
  - *Risk:* Over-requesting permissions leads to app rejection by Google or low user trust.
  - *Prevention:* Strip out any auto-added permissions not strictly used.
- [ ] **State Management Review:** Ensure `flutter_riverpod` providers handle errors gracefully and don't fail silently.
  - *Risk:* Unhandled state causes white screens of death or infinite loading.
- [ ] **Check Deep Linking:** If `url_launcher` or `go_router` manages deep links, ensure `assetlinks.json` is correctly hosted on your domain.
  - *Risk:* Broken deep links result in poor UX and failed marketing campaigns.

## 2. Security & Data Privacy
*Hardening the app against local and network exploitation.*

- [ ] **Secure Local Storage:** The app uses `shared_preferences` and `isar_community`. Are you storing sensitive PII in plain text?
  - *Risk:* Local database extraction allows attackers/malware to steal user data.
  - *Prevention:* Encrypt sensitive preferences (consider `flutter_secure_storage`). Since Isar doesn't natively encrypt completely free, ensure no critical PII is stored without manual AES encryption if required by law.
- [ ] **Network Security (HTTPS):** All `http` requests must use HTTPS. 
  - *Risk:* Man-in-the-middle (MITM) attacks.
  - *Prevention:* Disable cleartext traffic in Android network security config.
- [ ] **Obfuscation & Minification:** Ensure Dart code is obfuscated.
  - *Action:* Build with `flutter build appbundle --obfuscate --split-debug-info=/<dir>`.

## 3. Legal, Compliance & Hosting
*Bureaucracy required to exist on the internet legally.*

- [ ] **Privacy Policy:** You MUST have a publicly hosted Privacy Policy URL.
  - *Risk:* Immediate rejection by Google Play.
  - *Action:* Draft a policy declaring what data you collect, how Isar stores it locally, and what `http` sends externally. Host it (GitHub Pages is free).
- [ ] **Terms of Service (EULA):** Define the limits of liability.
- [ ] **Open Source Licenses:** Ensure the "Notices" page is accessible within the app.
  - *Risk:* Violating BSD/MIT license terms of your dependencies (e.g., `google_fonts`, `riverpod`).
  - *Action:* Use `showLicensePage()` in Flutter.
- [ ] **Hosting Infrastructure:** If you have a backend, ensure it scales and has DDoS protection (e.g., Cloudflare) before traffic hits.

## 4. Build & Signing Optimization
*Properly setting up the Android artifact.*

- [ ] **Update App Version (`pubspec.yaml`):** Current is `0.0.5+5`. Determine if you are launching at `1.0.0+X`.
- [ ] **Produce Keystore:** Generate an upload keystore for Play App Signing.
  - *Action:* Run `keytool -genkey -v -keystore upload-keystore.jks ...`
  - *Risk:* Losing this keystore prevents you from ever updating the app again unless Play App Signing is enabled (which you must use).
  - *Prevention:* Back up the `.jks` file and passwords in a secure password manager.
- [ ] **Configure `build.gradle.kts`:** Set up the `signingConfigs` in `android/app/build.gradle.kts` to reference a `key.properties` file securely (not checked into git).
- [ ] **Build App Bundle (AAB):** Google requires AAB, not APK.
  - *Action:* `flutter build appbundle`.

## 5. Store Assets & Marketing
*What the user sees before installing.*

- [ ] **App Icon:** Already handled via `flutter_launcher_icons`, but ensure it looks good on both light and dark mode devices without clipping.
- [ ] **Feature Graphics & Screenshots:**
  - Need 1 High-res icon (512x512).
  - Need 1 Feature Graphic (1024x500).
  - Need Phone & Tablet screenshots (min 2, max 8 per type).
  - *Risk:* Ugly store pages convert poorly.
- [ ] **Store Listing Text:** Short description (80 chars), Full description (4000 chars) optimized for ASO (App Store Optimization).

## 6. Google Play Console Setup

- [ ] **Developer Account:** Pay the $25 one-time fee. Verify identity (requires government ID).
- [ ] **App Content Questionnaire:**
  - Complete the Data Safety form (accurately reflecting `shared_preferences` and network logging).
  - Complete Content Rating (IARC).
  - Declare if the app is a News app or targets Children.
- [ ] **Internal / Closed Testing:**
  - Upload the AAB to the Closed Testing track.
  - *Constraint:* For new personal accounts, Google requires 20 testers to opt-in for 14 straight days before allowing a Production release. 

## 7. Post-Release Strategy

- [ ] **Crash Reporting:** `package_info_plus` is present but no crashlytics is detected.
  - *Risk:* Releasing without Firebase Crashlytics or Sentry means you are flying blind on production crashes.
  - *Action:* Integrate a crash reporter.
- [ ] **Analytics:** How do you know what features users use? (Consider Mixpanel or Firebase Analytics, and update the Privacy Policy accordingly).
- [ ] **Update Pipeline:** Plan how to handle hotfixes (e.g., fast tracks in Play Console).