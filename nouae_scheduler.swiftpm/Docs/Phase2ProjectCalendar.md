# nou ae Phase 2: Project Calendar

Phase 2 adds Apple Calendar creation for Projects. Reminder sync and WorkBlock event sync remain excluded.

## Load crash hotfix

Phase 2 now uses a separate bundle identifier: `com.auagna.nouae-scheduler.phase2`.

`Project.syncStateRawValue` also declares a persisted default value. This keeps Phase 2 isolated from older Phase 1 SwiftData files and makes new Project records migration-safe.

## Active structure additions

```text
Phase1App/
├── Services/
│   ├── AppServices.swift
│   ├── EventKitManager.swift
│   ├── CalendarSyncManager.swift
│   └── SyncError.swift
├── Components/
│   ├── ProjectCard.swift
│   └── SyncStatusBadge.swift
├── Support/
│   └── ColorHex.swift
└── Views/
    └── ProjectsView.swift
```

Modified files:
- `Models/Project.swift`
- `Stores/ProjectStore.swift`
- `App.swift`
- `ContentView.swift`
- `Package.swift`

## Implemented rules

- Project creation first saves a local SwiftData Project and default memo sections.
- The app then requests Calendar access and creates one Apple Calendar with the same Project title.
- The created Calendar identifier, title, and color hex are saved on the Project.
- Calendar colors are read-only in nou ae. No code changes Apple Calendar colors.
- If Calendar creation fails, the local Project remains and its sync state becomes `failed`.
- Projects entry and the refresh button can detect missing linked Calendars and archive affected Projects.

## Permission handling

`EventKitManager` owns one `EKEventStore` instance.

- iOS 17 and later: `requestFullAccessToEvents()`
- Earlier iOS fallback: `requestAccess(to: .event)`

`Info.plist` already contains:
- `NSCalendarsFullAccessUsageDescription`
- `NSCalendarsUsageDescription`

## Manual paste order

1. Add the four files under `Services`.
2. Update `Models/Project.swift`.
3. Update `Stores/ProjectStore.swift`.
4. Add `Support/ColorHex.swift`.
5. Add both files under `Components`.
6. Add `Views/ProjectsView.swift`.
7. Update `ContentView.swift`.
8. Update `App.swift`.
9. Update `Package.swift`.

## iPad reload steps

1. Remove the previously downloaded local Playgrounds copy from the iPad Files app.
2. Download the latest GitHub archive again.
3. Unzip it once.
4. Open the new `nouae_scheduler.swiftpm` package in Swift Playgrounds.
5. Do not overwrite the earlier local copy in place.

## iPad test scenario

1. Run the newly downloaded package and open `Projects`.
2. Tap the plus button.
3. Enter:
   - Project title: `기능사 공부`
   - Type: `Study`
   - Status: `Active`
   - Goal: `실기 시험 대비 루틴 만들기`
4. Tap `생성` and allow full Calendar access.
5. Open Apple Calendar and confirm a Calendar named `기능사 공부` exists.
6. Return to nou ae and confirm the Project card shows a Calendar color dot, linked Calendar title, and `Synced` badge.
7. Delete the `기능사 공부` Calendar in Apple Calendar.
8. Return to nou ae, open Projects, and tap the refresh icon.
9. Confirm the Project moves into the `Archived` section and displays a failed sync badge.

## Expected errors

### Permission denied
Open iPad Settings and allow Calendar full access for nou ae. Then return to Projects and create a new Project or tap refresh.

### Calendar source not found
Open Apple Calendar and confirm an iCloud Calendar account or another writable default Calendar exists.

### Package still crashes while loading
Verify that the old local package was removed before opening the fresh download. If it still crashes, capture the first visible Swift Playgrounds error line.

## Deferred to Phase 3+

- Project Dashboard details
- Apple Reminders sync
- WorkBlock event sync
- Calendar event list
- Drag and drop scheduling
