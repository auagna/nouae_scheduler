# nou ae MVP

`SwiftDataApp` is the active iPad Swift Playgrounds target. The package uses SwiftUI, SwiftData, and EventKit only.

## Main structure

```text
SwiftDataApp/
├── App.swift
├── Models/          SwiftData entities and enums
├── Stores/          local-first data operations
├── Sync/            EventKit access, Calendar sync, Reminder sync, active refresh
├── Support/         ModelContainer, snapping, color, sample data
├── Components/      ProjectCard, status badge, CalendarBoard, ExecutionPanel
└── Views/           Dashboard, Calendar, Projects, Plan, Log
```

## Implemented MVP loop

- Dashboard summarizes planned, in-progress, completed, delayed, and stopped work.
- Project creation creates one Apple Calendar and reads its color without overwriting it.
- Projects are grouped by status and open a Project Dashboard.
- RawTask quick capture exports to Apple Reminders.
- Apple Reminders import upserts by `reminderIdentifier` and avoids duplicates.
- Plan uses a 24-hour Calendar Board. RawTask supports tap placement and drag placement.
- WorkBlock moves vertically and resizes from top or bottom handles with 10-minute snapping.
- Calendar event save waits for a 3-second debounce after edits.
- App activation reconciles linked WorkBlocks from Apple Calendar. Apple values win for MVP conflicts.
- Deleted linked calendars archive their Projects.
- Calendar provides Month grid, Week columns, and Day list with Apple Calendar colors.
- Log is user-authored. Saving a next adjustment also creates a local `NextAdjustment`.

## Permission strings

`Info.plist` includes `NSCalendarsFullAccessUsageDescription` and `NSRemindersFullAccessUsageDescription` plus legacy keys for compatibility.

## iPad test scenario

1. Download the latest GitHub archive and open `nouae_scheduler.swiftpm` in Swift Playgrounds.
2. Run the app. Open `Projects` and create `nou ae 개발`.
3. Allow full Calendar access. Confirm the Calendar app contains a new `nou ae 개발` calendar.
4. Open `Plan`. Choose `nou ae 개발` as the placement project.
5. Add a RawTask title. Allow full Reminders access and confirm it appears in Reminders.
6. Drag the RawTask onto the board or tap it for current-time placement.
7. Drag the WorkBlock vertically, then resize it using the top and bottom handles.
8. Wait at least 3 seconds. Confirm the project calendar event exists without a category prefix.
9. Change the event time in Apple Calendar, return to nou ae, and confirm Plan reflects the Apple value.
10. Open `Calendar` and switch Day, Week, and Month.
11. Open `Log`, save a reflection and next adjustment, then confirm Dashboard reflects the adjustment.

## Known MVP limits

- Calendar Day view is a readable event list; the detailed editable time ruler lives in Plan.
- Calendar filters and Plan layout persist locally with `AppStorage`.
- Reminder import runs when the app becomes active after permission is granted and also has a manual refresh button in Plan.
- Execution suggestions are visible in Plan when a planned block reaches its start time. Background notifications are a later phase.

## Next implementation step

1. Add optional local notifications for start and end suggestions.
2. Add a completion sheet with an immediate optional Log shortcut.
3. Add memo editing and project archive controls in Project Dashboard.
4. Add dedicated sync recovery actions for failed blocks.
