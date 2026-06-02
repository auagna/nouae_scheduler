# nou ae Phase 2: Project Calendar

Phase 2 adds Apple Calendar creation for Projects. Reminder sync and WorkBlock event sync remain excluded.

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

## iPad test scenario

1. Download a fresh copy of the repository and open `nouae_scheduler.swiftpm` in Swift Playgrounds.
2. Run the app and open `Projects`.
3. Tap the plus button.
4. Enter:
   - Project title: `기능사 공부`
   - Type: `Study`
   - Status: `Active`
   - Goal: `실기 시험 대비 루틴 만들기`
5. Tap `생성` and allow full Calendar access.
6. Open Apple Calendar and confirm a Calendar named `기능사 공부` exists.
7. Return to nou ae and confirm the Project card shows a Calendar color dot, linked Calendar title, and `Synced` badge.
8. Delete the `기능사 공부` Calendar in Apple Calendar.
9. Return to nou ae, open Projects, and tap the refresh icon.
10. Confirm the Project moves into the `Archived` section and displays a failed sync badge.

## Expected errors

### Permission denied
Open iPad Settings and allow Calendar full access for nou ae. Then return to Projects and create a new Project or tap refresh.

### Calendar source not found
Open Apple Calendar and confirm an iCloud Calendar account or another writable default Calendar exists.

### Immediate launch crash after upgrading from Phase 1
`Project` gained a persisted sync-state field. Delete the older local Swift Playgrounds app copy and open a fresh download for this Phase test.

## Deferred to Phase 3+

- Project Dashboard details
- Apple Reminders sync
- WorkBlock event sync
- Calendar event list
- Drag and drop scheduling
