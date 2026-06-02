# nou ae Phase 1 · 2 · 3 Clean Restart

The active Swift Playgrounds target is now `Phase123App`.

Earlier `Phase1App` and `SwiftDataApp` experiments remain in GitHub for reference but are excluded from compilation.

## Why the target changed

Repeated load crashes can come from accumulated source files or incompatible SwiftData stores. The clean restart uses:

- target path: `Phase123App`
- bundle identifier: `com.auagna.nouae-scheduler.phase123`
- bundle version: `3`
- fresh SwiftData schema using persisted raw strings for enum-backed fields

## Implemented phases

### Phase 1
- SwiftUI app entry point
- Dashboard, Calendar, Projects, Plan, Log tabs
- SwiftData models
- Store layer
- Dashboard sample data button

### Phase 2
- one `EKEventStore`
- Calendar full-access permission request
- Project creation creates an Apple Calendar with the same title
- Apple Calendar identifier, title, and read-only color hex saved to Project
- missing Calendar detection archives Project

### Phase 3
- Projects index grouped by status
- ProjectCard summary
- ProjectCard push navigation to Project Dashboard
- header, goal, progress, Inbox, Today Work, memo sections, next adjustment, recent logs
- manual Project status change
- Project Inbox RawTask appears in Plan Inbox

## Active structure

```text
Phase123App/
├── App.swift
├── ContentView.swift
├── Models/
├── Stores/
├── Services/
├── Support/
├── Components/
└── Views/
```

## iPad reload procedure

Do not overwrite an earlier local copy.

1. Open the iPad Files app.
2. Delete earlier downloaded `nouae_scheduler` folders and extracted copies.
3. Download the latest GitHub ZIP again.
4. Extract the ZIP once.
5. Open the new `nouae_scheduler.swiftpm` package in Swift Playgrounds.
6. Run the app.

## Smoke test

1. Confirm five tabs appear.
2. On Dashboard, tap `샘플 데이터 생성`.
3. Open Projects and select `nou ae 개발`.
4. Confirm Project Dashboard shows goal, Inbox, Today Work, memo sections, next adjustment, and recent logs.
5. Add a RawTask in Project Inbox.
6. Open Plan and confirm the RawTask appears.
7. Return to Projects and add `기능사 공부`.
8. Allow Calendar full access.
9. Confirm Apple Calendar contains a `기능사 공부` calendar.
10. Delete that Calendar in Apple Calendar.
11. Return to Projects and tap refresh.
12. Confirm `기능사 공부` moves to Archived.

## Deferred

- Reminder sync
- WorkBlock event sync
- Calendar Day / Week / Month flow views
- Drag and drop planning

## If loading still crashes

Capture the first visible Swift Playgrounds error line. A screenshot of the first error is more useful than the final cascade of errors.
