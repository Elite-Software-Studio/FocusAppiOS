# Firebase Migration Plan: Local-First FocusZone

## 1. Goals

- **Replace CloudKit with Firebase** (Firestore + Auth) for optional cloud sync and cross-device backup.
- **Keep the app local-first**: the app must work fully offline. No internet connection required for core usage.
- **Local = source of truth**: all reads and writes go to local SwiftData first; Firebase is a sync layer that runs when online.

---

## 2. Principles

| Principle | Meaning |
|-----------|--------|
| **Local-first** | All CRUD uses SwiftData. UI never waits on the network. |
| **Offline-capable** | Full task and inbox usage without network. Sync is best-effort when online. |
| **Sync when online** | When the app is online and user is signed in (or anonymous), background sync pushes/pulls with Firestore. |
| **No blocking** | No “waiting for sync” to use the app. Sync happens in the background. |

---

## 3. Current State (to change)

- **Task persistence**: SwiftData with `ModelConfiguration(cloudKitDatabase: .automatic)` — CloudKit-backed.
- **QuickNote**: Separate SwiftData container, local-only (`cloudKitDatabase: .none`).
- **Sync**: `CloudSyncManager` syncs Task with CloudKit (fetch remote, merge, upload local).
- **UI**: Settings shows `CloudKitSyncStatusView`; app triggers sync on launch and when becoming active.

---

## 4. Target Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         FocusZone App                             │
├─────────────────────────────────────────────────────────────────┤
│  UI (Timeline, Inbox, Settings, TaskForm, …)                     │
│       │                                                           │
│       ▼                                                           │
│  Read/Write ──────────────►  SwiftData (local only)               │
│       │                         • Task (local store)              │
│       │                         • QuickNote (local store)          │
│       │                                                           │
│       │  [Background, when online + signed in]                   │
│       ▼                                                           │
│  FirebaseSyncService                                             │
│       │  Push: local changes → Firestore                          │
│       │  Pull: Firestore → merge into SwiftData                  │
│       ▼                                                           │
│  Firebase (Firestore + Auth)                                     │
│       • users/{uid}/tasks/{taskId}                                │
│       • users/{uid}/quickNotes/{noteId}                           │
└─────────────────────────────────────────────────────────────────┘
```

- **SwiftData**: Becomes **local-only** for both Task and QuickNote (no CloudKit).
- **Firebase**: Firestore holds a mirror of tasks and quick notes per user; Auth identifies the user (anonymous or signed-in).
- **Sync**: One service (e.g. `FirebaseSyncService`) pushes local changes and pulls remote changes when online, merging into SwiftData with a clear conflict strategy.

---

## 5. Data Model Mapping

### 5.1 Task → Firestore

- **Collection**: `users/{userId}/tasks` (or `tasks` with `userId` in document for security rules).
- **Document ID**: `task.id.uuidString` so local and remote share the same ID.
- **Flat, serializable fields** (no SwiftData `@Relationship` in Firestore):

| SwiftData (Task) | Firestore field | Type |
|------------------|-----------------|------|
| id | document id = id.uuidString | string |
| title | title | string |
| icon | icon | string |
| startTime | startTime | timestamp |
| durationMinutes | durationMinutes | number |
| isCompleted | isCompleted | bool |
| taskTypeRawValue | taskTypeRawValue | string? |
| statusRawValue | statusRawValue | string |
| actualStartTime | actualStartTime | timestamp? |
| repeatRuleRawValue | repeatRuleRawValue | string |
| createdAt | createdAt | timestamp |
| updatedAt | updatedAt | timestamp |
| colorHex | colorHex | string |
| parentTaskId | parentTaskId | string? |
| isGeneratedFromRepeat | isGeneratedFromRepeat | bool |
| focusSettingsData | focusSettingsData | bytes (base64 or omit for v1) |

- **Relationships**: For sync, treat parent/children as IDs only (parentTaskId). Virtual/repeat-generated instances can be synced as separate documents or derived on clients; v1 can sync “root” tasks and key instances only to keep rules simple.

### 5.2 QuickNote → Firestore

- **Collection**: `users/{userId}/quickNotes`
- **Document ID**: `note.id.uuidString`

| SwiftData (QuickNote) | Firestore |
|----------------------|-----------|
| id | document id |
| content | content (string) |
| createdAt | createdAt (timestamp) |

### 5.3 Sync Metadata (optional but recommended)

- Add a small “sync state” store (e.g. in UserDefaults or a SwiftData model) to track:
  - Last successful push timestamp per collection.
  - Last successful pull timestamp.
  - Pending change flags or “dirty” IDs so we know what to push.

---

## 6. Sync Strategy (Local-First)

### 6.1 Push (local → Firestore)

- **When**: After local saves (e.g. in `TimelineViewModel`, `TaskFormView`, `InboxView`); also on a short debounced “sync” after a batch of changes.
- **How**: For each created/updated Task or QuickNote, write to Firestore with document id = `id.uuidString`. Deletes: remove document (or set a “deleted” flag if you want soft delete).
- **Offline**: If no network, skip push; next time the app is online, push will run again (e.g. from a periodic sync or on app foreground).

### 6.2 Pull (Firestore → local)

- **When**: On app launch when online; optionally when app comes to foreground; optionally on a timer when online.
- **How**:
  1. Fetch `users/{uid}/tasks` and `users/{uid}/quickNotes` (e.g. where `updatedAt > lastPullTime` if you store it).
  2. For each document: if local has same id, compare `updatedAt`; if remote is newer, apply to SwiftData (update or insert). If local has no row, insert.
  3. Conflict resolution: **last-write-wins (LWW)** using `updatedAt` is enough for v1.

### 6.3 Conflict Resolution (v1)

- Use **last-write-wins** on `updatedAt`.
- If two devices edit the same task offline, the last sync to complete “wins.” Optional later: show a conflict UI or merge fields.

### 6.4 Order of Operations

1. **App launch (online)**: Pull from Firestore → merge into SwiftData → then UI reads from SwiftData.
2. **User creates/edits/deletes**: Write to SwiftData only; UI updates immediately. Then trigger background push.
3. **App foreground (online)**: Optional pull then push (or push then pull with LWW).

---

## 7. Auth Strategy

- **Anonymous Auth**: Sign in anonymously on first launch so each device has a stable `uid`. No user action required; app works offline and “just works” when online.
- **Optional upgrade**: Later, link anonymous to email/Google so the same user can use multiple devices with the same Firestore data.
- **No auth required to use app**: All features work without an account; sync is an enhancement when online.

---

## 8. Firebase Setup (one-time)

1. **Firebase project**
   - Create project in Firebase Console.
   - Add iOS app (Bundle ID), download `GoogleService-Info.plist`, add to Xcode.

2. **Firestore**
   - Create database (production mode).
   - Security rules: only allow read/write for `users/{userId}/tasks` and `users/{userId}/quickNotes` when `request.auth != null` and `request.auth.uid == userId`.

3. **Auth**
   - Enable Anonymous (and optionally Email/Google for later).
   - No forced sign-in screen for v1; anonymous sign-in in background.

4. **SDK**
   - Add Firebase iOS SDK (Swift Package: `firebase-ios-sdk`), include FirebaseAuth and FirebaseFirestore.

---

## 9. Implementation Phases

### Phase 1: Local-Only SwiftData (remove CloudKit dependency)

- Remove CloudKit from the Task container: use `ModelConfiguration(cloudKitDatabase: .none)` (or equivalent local-only config) for the Task container.
- Remove or stub `CloudSyncManager` usage (no sync calls).
- Remove CloudKit from entitlements and any CloudKit-specific code paths.
- Keep all UI and business logic; app runs 100% on SwiftData. **Result: app is local-first and works offline; no sync yet.**

### Phase 2: Add Firebase and Auth

- Add Firebase SDK and `GoogleService-Info.plist`.
- Add `FirebaseAuthService`: sign in anonymously on launch (when online); expose `userId` and auth state.
- No UI change; just “ready for sync.”

### Phase 3: Firestore Sync Service

- Add `FirebaseSyncService` (or `FirestoreSyncService`):
  - Push: on local Task/QuickNote save (or debounced), write to Firestore under `users/{uid}/...`.
  - Pull: on launch/foreground (when online), fetch from Firestore and merge into SwiftData (LWW).
  - Expose sync status (idle / syncing / error) for Settings.
- Add DTOs/codable structs for Task and QuickNote to map between SwiftData and Firestore documents.
- Do not change existing SwiftData model APIs; only add a sync layer that reads/writes SwiftData and Firestore.

### Phase 4: Wire Sync into App Lifecycle

- In `FocusZoneApp`: on launch and on `didBecomeActive`, call sync service (pull then push or as designed).
- Replace `CloudKitSyncStatusView` with `FirebaseSyncStatusView` (or generic “Sync” status) in Settings.
- Remove all CloudKit references and delete `CloudSyncManager` (and CloudKit entitlements if unused).

### Phase 5: Optional Enhancements

- QuickNote sync (if not done in Phase 3).
- Link anonymous auth to email/Google for multi-device.
- Slightly more advanced conflict handling or “pending changes” indicator in UI.

---

## 10. What to Remove / Replace

| Current | Action |
|---------|--------|
| `ModelConfiguration(cloudKitDatabase: .automatic)` for Task | Change to local-only (e.g. `cloudKitDatabase: .none`) |
| `CloudSyncManager` | Remove; replace with `FirebaseSyncService` (or similar) |
| `CloudKitSyncStatusView` | Replace with Firebase/sync status view |
| FocusZoneApp: `cloudSyncManager`, sync on launch/foreground | Use new sync service |
| Settings: CloudKit section | Replace with Firebase/Sync section |
| Entitlements: iCloud / CloudKit | Remove if no longer needed |
| Imports and references to CloudKit | Remove |

---

## 11. File / Component Checklist

- **App**
  - `FocusZoneApp.swift`: Task container → local-only; inject Firebase sync service; trigger sync on launch/foreground.
  - Remove CloudKit imports and `CloudSyncManager` usage.
- **Models**
  - Keep `Task` and `QuickNote` as SwiftData models; add Codable/DTO layer for Firestore only (e.g. in a Sync or Firebase module).
- **New**
  - `FirebaseAuthService` (anonymous sign-in, uid).
  - `FirebaseSyncService` (push/pull, LWW, status).
  - `FirestoreSyncStatusView` or reuse a generic sync status view.
- **Remove / refactor**
  - `CloudSyncManager.swift` (remove).
  - `CloudKitSyncStatusView.swift` (replace with Firebase sync view).
  - CloudKit in entitlements and Settings copy.

---

## 12. Testing Considerations

- **Offline**: Turn off network; create/edit/delete tasks and notes; confirm everything works and persists locally.
- **Online**: After some local changes, go online; confirm push and pull (e.g. check Firestore console and other device/simulator if applicable).
- **Conflict**: Two devices offline, edit same task, then sync both; confirm LWW behavior.
- **No regression**: Timeline, Inbox, task form, notifications, and widgets should behave as before; only sync backend changes.

---

## 13. Summary

- **Local-first**: SwiftData is the only source of truth for the UI; all features work offline.
- **Firebase**: Firestore + Auth used only for optional sync when online; no blocking of the app.
- **Migration path**: Remove CloudKit → make Task store local-only → add Firebase Auth → add Firestore sync service → replace CloudKit UI with sync status. Result: same UX, Firebase instead of CloudKit, with a strict local-first guarantee.
