# Consolidated Feature Plan: Self-Updater & Privacy-First Developer Telemetry

## 🚨 Vercel Telemetry Backend - Post-Mortem & Restart Plan 🚨

### What Went Fatally Wrong
1. **Workspace Pollution (The 2.7GB Upload Issue):** We mixed the Node.js/Vercel backend files (`package.json`, `api/`, `.vercel`) directly into the Flutter project's main repository folder. This caused the Vercel CLI to attempt to deploy the entire Flutter project (including massive `/build/`, `/.dart_tool/`, and Android/Linux compiled binaries). This resulted in massive uploads, freezing, and corrupted deployments.
2. **500 Server Errors:** The Vercel serverless functions (`api/ping.js`, `api/dashboard.js`) were crashing due to missing environment variables (`REDIS_URL`) and dependency mismatches (ESM vs CommonJS, Upstash vs ioredis) in the production environment.

### Next Time: Fresh Telemetry Web Server Setup
- **Complete Separation:** Create a completely separate folder/repository (e.g., `gate-tracker-telemetry-backend`) exclusively for the Vercel project. NEVER mix the Flutter project files with the Vercel deployment files.
- **Dependencies Setup:** Initialize a clean Node project, install `ioredis` properly, and link it via the Vercel CLI.
- **Environment Targeting:** Ensure `REDIS_URL` and `STATS_API_KEY` are securely defined in the Vercel dashboard prior to running the deployment.

### Current In-App Telemetry (Flutter Client)
- **What it does:** Generates a GDPR-compliant anonymous token by hashing a secure device ID and the current date (SHA-256). It executes a fire-and-forget POST request to a defined telemetry endpoint upon app launch containing the `dailyToken`, `version`, and `platform`.
- **What it needs:** A valid, active production Web URL to ping. (Currently, the app might throw silent failures since the backend is destroyed).

### Storage Web Server (How it Functions/Should Work)
- **The Flow:** The serverless functions (like `api/ping.js`) receive the POST request, extract the token, and interact with a Redis database instance.
- **Deduplication:** By storing the token in a Redis Set (e.g., `dau:2026-05-28`), duplicate pings from the same user opening the app multiple times a day are automatically ignored.
- **Dashboard:** A secure edge function (`api/dashboard.js`) queries the Redis Set's size (`scard`) to render a fast HTML analytical dashboard for admin use.

---

## 🔴 Current Active Tasks (pre-v1.0.0 release)

> 4 tasks to complete before tagging `v1.0.0` on GitHub.

### 1. Complete Preset Data
- [x] User to provide playlist links + video counts for all subjects
- [x] Update category names and subject names as decided by user
- [x] Fully populate `applyDefaultPreset()` in `isar_service.dart` (currently only 6 subjects have data)

### 2. Migrate Database: Isar → Drift (With Dynamic Customization)
- [x] Remove `isar_community`, `isar_generator`, and old model files (`lib/database/models/subject.dart`, `subject.g.dart`)
- [x] Add `drift`, `sqlite3_flutter_libs`, `drift_dev` packages in `pubspec.yaml`
- [x] Implement Relational Drift Database Schema:
  - **Categories Table**: `id` (int PK autoIncrement), `name` (text), `position` (int for sorting), `color` (int hex color)
  - **Subjects Table**: `id` (int PK autoIncrement), `name` (text), `categoryId` (int foreign key references categories), `completedVideos` (int), `totalVideos` (int), `playlistLink` (text), `sourceName` (text), `isActive` (bool), `position` (int for sorting within category), `color` (int nullable custom color)
- [x] Implement CRUD & Customization APIs in `AppDatabase`:
  - **Edit/Create/Delete**: Dynamic addition, renaming, and removal of categories and subjects
  - **Reorder**: Update category & subject `position` indexes to support drag-and-drop sorting
  - **Move**: Shift subjects from one category to another dynamically
  - **Colors**: Assign custom colors to categories and custom override colors to subjects
- [x] Update state management (`subject_provider.dart`):
  - Stream categories with their nested subjects ordered by positions
  - Expose controllers for all creation, reordering, and customization actions
- [x] Implement Premium Dashboard Empty State:
  - Keep main dashboard layout shell, show "?" as main progress percentage
  - Offer inline options: **"Load Preset"** and **"Create Category"**
  - Show Quick Guide instructions ("To Create New Category, Long Press...") with an "Understood" button before launching the dialog.
- [x] Verify functionality and platforms:
  - Test seeding presets, manual additions, moving, drag-and-drop reordering, and color picking
  - Ensure all database state syncs instantly across Android, Linux, and Windows desktop targets

### 3. Implement Developer Telemetry (Privacy-First DAU)
- [x] Set up Vercel KV (Redis) project + deploy `api/ping.js` and `api/stats.js`
- [x] Add `telemetry_service.dart` — SHA256 daily token, fire-and-forget POST on app launch
- [x] Update README and Privacy Policy note (data is fully anonymous)

### 4. Bump to v1.0.0 + GitHub Release
- [x] Update version in `pubspec.yaml`, `dashboard_screen.dart`, `settings_sheet.dart` (×2)
- [ ] Push to `main`, create GitHub Release tag `v1.0.0` with APK attached
- [ ] Self-updater will then work end-to-end for all future users

---


## 1. Feature: Privacy-First Developer Telemetry via Vercel KV (Redis)

To bypass the complexity of external SQL connection pools or database certificates, telemetry utilizes **Vercel KV (Redis)**. This edge-based Key-Value engine is configured directly within Vercel in 1-click, auto-injecting credentials directly to the serverless backend.

### A. Privacy Hashing Logic (GDPR Compliant)
Since pings are strictly anonymous and gather no personal user data, no complex settings toggle or authorization banner is required. Before transmitting, the app guarantees total security by computing a daily hash:
$$\text{Daily Token} = \text{SHA256}(\text{client\_id} + \text{current\_date\_string})$$
This token changes dynamically every day. You can only compute active pings per 24 hours and can never link user history across different days.

### B. Vercel KV Serverless Integration
We utilize a Redis **Set** corresponding to the date. Redis sets naturally deduplicate duplicate launches (e.g. if the user opens the app 5 times today, they only occupy one element in the set).

#### 1. The Telemetry Ping Endpoint (`api/ping.js`)
Exposed as a simple POST handler on your Vercel project:
```javascript
import { kv } from '@vercel/kv';

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  
  const { dailyToken, version, platform } = req.body;
  const today = new Date().toISOString().split('T')[0]; // e.g. "2026-05-27"
  
  const setKey = `dau:${today}`;
  
  // 1. Add token to the set of daily users (deduplicates automatically)
  await kv.sadd(setKey, dailyToken);
  
  // 2. Set 30 days expiration on the key to save storage automatically
  await kv.expire(setKey, 30 * 24 * 60 * 60);
  
  // 3. Log metadata for version and platform distributions
  const metadataKey = `meta:${today}:${version}:${platform}`;
  await kv.incr(metadataKey);
  await kv.expire(metadataKey, 30 * 24 * 60 * 60);

  return res.status(200).json({ success: true });
}
```

#### 2. Reading Statistics Endpoint (`api/stats.js`)
Protected by a secure query parameter, you can retrieve the active user counts:
```javascript
import { kv } from '@vercel/kv';

export default async function handler(req, res) {
  // Simple stats authorization key
  if (req.query.key !== process.env.STATS_API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const today = new Date().toISOString().split('T')[0];
  
  // SCARD instantly returns the size of the unique set (unique users)
  const activeUsers = await kv.scard(`dau:${today}`);
  
  return res.status(200).json({ 
    date: today,
    daily_active_users: activeUsers 
  });
}
```

---

## 2. Summary of Implementation Decisions

1.  **No Telemetry UI Clutter**: Because data is completely anonymous and privacy-friendly, there is no need to add cluttering disclaimer switches or opt-ins to the settings interface.
2.  **Backend Telemetry**: Standardized strictly on **Approach 1 (Vercel KV / Redis)**. It runs in 1-click on Vercel, auto-deduplicates active users, and maintains a 30-day self-destruct cycle to keep the free storage quota clean forever.

---

## 3. Additional UI/UX Refinements & Future Ideas

### Planned Improvements
1. Update category order customization support.
2. Complete preset template system for faster setup flows.
3. Reduce top header height slightly to improve dashboard usable space.
4. Add settings option for 2 or 3 decimal precision in main progress percentage.
5. While scrolling down, fade the main app logo into a miniature version integrated into the main progress bar.
6. Remove standalone settings gear icon and move the GATE Progress Tracker logo/title alignment toward the left side.
7. Scrolling upward at the top edge should require a short hold gesture before revealing settings, avoiding accidental transitions.
8. Alternative settings access: long-press and hold the “GATE Progress Tracker” title to open settings.
9. Extend startup animation system so the “days left” counter receives the same animated introduction as the main progress bar.
10. Explore a cleaner, more premium settings screen layout and interaction design.

### Small Future App Ideas
- Study streak visualization heatmaps.
- Smart revision reminders based on weak subjects.
- Adaptive motivational widgets.
- Offline-first sync/export profiles.
- Multi-exam support beyond GATE.
- Semester planner integration.
- AI-assisted study breakdown recommendations.
- Widget support for Android home screen.
- Time estimation for syllabus completion.
- Competitive friend leaderboard system.
