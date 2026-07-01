# GATEletics Website Implementation Plan

This document outlines the plan for updating the GitHub Pages website for GATEletics to include all essential pages, navigation, and structure required for the Google Play Store release and general user support.

## 1. Essential Pages to Create/Update

### 1.1 Home (`index.html`)
- **App Name and Logo:** Prominently displayed.
- **Short Description:** Clear, concise value proposition.
- **Screenshots:** Visual preview of the app.
- **Key Features:** Highlight main functionalities (Checklists, Focus Mode, Cloud Sync).
- **Download Buttons:** Link to Play Store (when published) and GitHub release/APK.
- **Web Version Link:** Link to the Vercel hosted web app.
- **GitHub Link:** Link to the open-source repository.

### 1.2 Privacy Policy (`privacy.html`)
- *Already exists in the repository.*
- Ensure it includes the recently added **Account Deletion** instructions.
- Ensure styling matches the rest of the website.

### 1.3 Terms of Service (`terms.html`)
- *Already exists in the repository.*
- Ensure styling matches the rest of the website.

### 1.4 Support (`support.html`)
- **Support Email:** `vishnunandan555@gmail.com`
- **FAQ Section:** Common questions and answers.
- **Bug Report Link:** Link to GitHub Issues.

### 1.5 Account Deletion (`delete-account.html`)
- **How to delete the account:** Step-by-step guide (in-app and out-of-app).
- **What data is deleted:** Clarify that all Firestore documents and Firebase Auth credentials are removed.
- **How long deletion takes:** Mention the 30-day timeframe for out-of-app requests.
- **Contact Email:** Provide the support email for deletion requests.

## 2. Navigation Structure

### Top Navigation Bar
- Home
- Features (Scroll to section on Home)
- Download (Scroll to section on Home)
- Support
- GitHub

### Footer Navigation
- Privacy Policy
- Terms of Service
- Support
- Delete Account
- GitHub
- MIT License
- © 2026 GATEletics

## 3. Nice-to-Have Features (Optional/Future)
- **Changelog / What's New:** Dedicated page or section.
- **Roadmap:** Future features planned.
- **FAQ:** Expanded frequently asked questions.

## 4. Execution Steps
1. **Design System:** Establish a consistent CSS theme (colors, typography) matching the GATEletics app.
2. **HTML Templates:** Create the base HTML structure with the common Header (Navigation) and Footer.
3. **Page Creation:** Implement `index.html`, `support.html`, and `delete-account.html`.
4. **Integration:** Update `privacy.html` and `terms.html` to use the new common Header and Footer.
5. **Testing:** Ensure mobile responsiveness and broken link checks.
6. **Deployment:** Push to the GitHub repository to automatically update GitHub Pages.
