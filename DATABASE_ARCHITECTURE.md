# Data Storage & Database Architecture — GATEletics

This document describes how GATEletics manages local relational storage, exports backup schemas, and synchronizes data with Google Cloud Firestore under a single-document strategy optimized for the free Firebase Spark plan.

---

## 💾 1. Physical Storage & Engines

GATEletics uses **[Drift](https://drift.simonbinder.eu/)** as its compile-safe Dart relational database mapping interface. Depending on the target environment, the physical SQLite engines are configured as follows:

| Platform | Engine / Database Type | Storage Directory / File Path |
| :--- | :--- | :--- |
| **Android** | SQLite (native driver) | `/data/data/com.vishnunandan.gateletics/app_flutter/gateletics.db` |
| **Linux** | SQLite (native driver) | `~/Documents/gateletics/gateletics.db` |
| **Windows** | SQLite (native driver) | `C:\Users\<username>\Documents\gateletics\gateletics.db` |
| **Web** | IndexedDB via WebAssembly | Browser-managed client-side database storage using local `sql-wasm.wasm` |

---

## 📊 2. Relational Database Schema (Drift)

The database schema is defined in [app_database.dart](file:///home/vishnunandan555/Projects/gate-tracker/lib/database/app_database.dart).

### Tables & Relationships
* **`Categories`**: Holds parent groups for course/playlist-based tracking.
  * `id` (`INTEGER` Primary Key Auto-Increment)
  * `name` (`TEXT`, 1-100 chars)
  * `position` (`INTEGER`, user reorder index)
  * `color` (`INTEGER`, HSL-mapped preset/custom accent color value)
  * `lastInteractedAt` (`DATETIME` Nullable, tracks sorting rank)
* **`Subjects`**: Holds individual course playlists.
  * `id` (`INTEGER` Primary Key Auto-Increment)
  * `name` (`TEXT`, 1-100 chars)
  * `categoryId` (`INTEGER` Foreign Key referencing `Categories(id)` ON DELETE CASCADE)
  * `completedVideos` (`INTEGER` Default 0)
  * `totalVideos` (`INTEGER`)
  * `playlistLink` (`TEXT` Default '')
  * `sourceName` (`TEXT` Default 'Source')
  * `isActive` (`BOOLEAN` Default FALSE)
  * `position` (`INTEGER`)
  * `color` (`INTEGER` Nullable)
* **`SyllabusCategories`**: Holds GATE syllabus divisions (e.g. "Core Computer Science", "Engineering Mathematics").
  * `id` (`INTEGER` Primary Key Auto-Increment)
  * `name` (`TEXT`, 1-100 chars)
  * `position` (`INTEGER`)
  * `color` (`INTEGER`)
  * `lastInteractedAt` (`DATETIME` Nullable)
* **`SyllabusTopics`**: Holds chapters/modules.
  * `id` (`INTEGER` Primary Key Auto-Increment)
  * `categoryId` (`INTEGER` Foreign Key referencing `SyllabusCategories(id)` ON DELETE CASCADE)
  * `name` (`TEXT`, 1-150 chars)
  * `position` (`INTEGER`)
* **`SyllabusTasks`**: Holds individual subtopics or checklists.
  * `id` (`INTEGER` Primary Key Auto-Increment)
  * `topicId` (`INTEGER` Foreign Key referencing `SyllabusTopics(id)` ON DELETE CASCADE)
  * `name` (`TEXT`, 1-200 chars)
  * `isCompleted` (`BOOLEAN` Default FALSE)
  * `position` (`INTEGER`)
* **`FocusSessions`**: Tracks Pomodoro, Freestyle, or Ultradian study sessions.
  * `id` (`INTEGER` Primary Key Auto-Increment)
  * `method` (`TEXT` e.g., "Pomodoro", "Freestyle")
  * `startTime` (`DATETIME`)
  * `durationSeconds` (`INTEGER`)
  * `accomplishments` (`TEXT` Nullable, stores JSON string list of checklist tasks achieved)
  * `progressDelta` (`REAL` Default 0.0, progress change recorded at session completion)

---

## 📦 3. JSON Backup & Restore Format

When a user exports their data (or when data is staged for Cloud Sync), the database is serialized into a single nested JSON document via [backup_service.dart](file:///home/vishnunandan555/Projects/gate-tracker/lib/database/backup_service.dart).

### Serialized Payload Example (Schema Version `3`)
```json
{
  "version": 3,
  "lastInteractedAt": "2026-07-04T09:00:00.000Z",
  "categories": [
    {
      "name": "Programming",
      "color": 4278190080,
      "position": 0,
      "lastInteractedAt": "2026-07-04T08:30:00.000Z"
    }
  ],
  "subjects": [
    {
      "name": "C Programming",
      "categoryName": "Programming",
      "completedVideos": 12,
      "totalVideos": 40,
      "playlistLink": "https://...",
      "sourceName": "YouTube",
      "isActive": true,
      "position": 0,
      "color": null
    }
  ],
  "syllabusCategories": [
    {
      "id": 1,
      "name": "Databases",
      "position": 0,
      "color": 4280190080,
      "lastInteractedAt": null
    }
  ],
  "syllabusTopics": [
    {
      "id": 1,
      "categoryId": 1,
      "name": "Normalization",
      "position": 0
    }
  ],
  "syllabusTasks": [
    {
      "id": 1,
      "topicId": 1,
      "name": "Identify 3NF vs BCNF",
      "isCompleted": true,
      "position": 0
    }
  ]
}
```

---

## ☁️ 4. Google Cloud Sync & Spark Plan Optimization

### The Single-Document Strategy
Firestore billing is heavily tied to the number of document read/write operations. To operate within the free limits of the **Firebase Spark Plan (1 GB Storage, 20k writes/day, 50k reads/day)**, GATEletics avoids using wide collection trees where each task or session is saved as a separate document.

Instead, the app maps each user to a **single document** inside the root `users` collection:
`users/{firebase_user_uid}`

```
users/ (Collection)
  └─ {uid} (Document)
       ├─ lastSyncedAt: timestamp
       └─ data: { ... complete serialized database payload ... }
```

### Flow of Cloud Sync
1. **Trigger:** Sync is triggered automatically on critical actions (completing a session, checking off tasks, or changing profiles) with a debounce timer.
2. **Export:** Local database tables are converted to the serialized JSON payload.
3. **Overwrite & Sync:** The document at `users/{uid}` is updated on Firebase Firestore.
4. **Offline Merging:** Since Firestore uses cache-first local synchronization, if a user makes changes offline, Firestore queues writes locally and merges conflicts cleanly using server timestamps when internet connection is restored.
