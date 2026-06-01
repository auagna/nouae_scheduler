# nou ae MVP

`SwiftDataApp` is the active Swift Playgrounds target. The MVP uses SwiftUI, SwiftData, and EventKit only.

## Folder structure

```text
SwiftDataApp/
├── App.swift
├── Models/
│   ├── Enums.swift
│   ├── Project.swift
│   ├── RawTask.swift
│   ├── WorkBlock.swift
│   ├── ProjectLog.swift
│   ├── ProjectMemoSection.swift
│   └── NextAdjustment.swift
├── Stores/
│   ├── AppStores.swift
│   ├── ProjectStore.swift
│   ├── RawTaskStore.swift
│   ├── WorkBlockStore.swift
│   ├── LogStore.swift
│   └── DashboardStore.swift
├── Sync/
│   ├── SyncError.swift
│   ├── EventKitManager.swift
│   ├── CalendarSyncManager.swift
│   ├── ReminderSyncManager.swift
│   └── AppServices.swift
├── Support/
│   ├── AppModelContainer.swift
│   ├── DateSnapper.swift
│   ├── ColorHex.swift
│   └── SampleDataSeeder.swift
└── Views/
    ├── MVPContentView.swift
    └── FoundationRootView.swift
```

## MVP rules

- Project creation creates one Apple Calendar and stores its identifier, title, and color.
- nou ae reads the Apple Calendar color. It does not overwrite it.
- WorkBlock is saved as an Apple Calendar Event after a 3-second debounce.
- Event titles remain plain text. Do not prepend category labels.
- RawTask quick capture exports to Apple Reminders.
- Reminder import upserts incomplete reminders into RawTask Inbox.
- Log stays inside SwiftData and is not created automatically.
- If a linked Apple Calendar disappears, `archiveProjectsWithMissingCalendars()` archives the linked project.

## Swift Playgrounds load order

When recreating files manually, use this order:

1. `Models/Enums.swift`
2. All remaining files in `Models/`
3. `Support/AppModelContainer.swift`, `Support/DateSnapper.swift`, `Support/ColorHex.swift`
4. All files in `Stores/`
5. All files in `Sync/`
6. `Support/SampleDataSeeder.swift`
7. `Views/MVPContentView.swift`
8. `App.swift`

When downloading from GitHub, open `nouae_scheduler.swiftpm` directly instead of pasting files individually.

## Permission strings

`Info.plist` includes:

- `NSCalendarsFullAccessUsageDescription`
- `NSRemindersFullAccessUsageDescription`
- legacy Calendar and Reminders usage descriptions for compatibility

## iPad test scenario

1. Download the latest repository archive from GitHub and open `nouae_scheduler.swiftpm` in Swift Playgrounds.
2. Run the app and open `Projects`.
3. Create a project named `nou ae 개발`.
4. Allow full Calendar access when prompted.
5. Confirm a new Apple Calendar named `nou ae 개발` appears in the Calendar app.
6. Open `Plan`, enter a RawTask title, and tap the plus icon.
7. Allow full Reminders access when prompted.
8. Confirm the RawTask appears in Apple Reminders.
9. Tap the RawTask in Plan to place it as a one-hour WorkBlock.
10. Wait at least 3 seconds.
11. Confirm the event appears in the project's Apple Calendar without a category prefix.
12. Open `Calendar` and switch Day, Week, and Month to confirm Apple events load.
13. Open `Log`, write a reflection, and confirm it appears in recent logs.

## Known MVP limits

- Plan currently provides tap-to-place before direct drag-and-drop placement.
- Block resize handles and live drag feedback are the next UI step.
- Calendar Day, Week, and Month currently share an event list presentation. Grid layouts are the next UI step.
- Reminder import is implemented in `ReminderSyncManager` but does not yet have a visible toolbar button.
- Calendar filter state is not yet persisted.

## Next implementation step

1. Add a real Plan calendar board with 10-minute drag snapping and resize handles.
2. Add Calendar day timeline, week columns, and month grid.
3. Add visible Reminder import and permission recovery controls.
4. Persist calendar filters and user-selected Plan layout.
5. Add start suggestion and end-of-block completion sheet.
