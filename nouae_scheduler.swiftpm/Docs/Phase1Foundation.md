# nou ae Phase 1 Foundation

`Package.swift` compiles only `Phase1App`. Earlier experiments remain in the repository but are excluded from the active Swift Playgrounds target.

## Scope

Included:
- App entry point
- Dashboard, Calendar, Projects, Plan, Log tabs
- SwiftData entities and ModelContainer
- Local-only Store skeletons
- Placeholder views
- Dashboard sample data button

Excluded until Phase 2 or later:
- EventKit
- Apple Calendar and Apple Reminders permissions
- Sync managers
- Drag and drop
- WorkBlock resize gestures

## Active file structure

```text
Phase1App/
├── App.swift
├── ContentView.swift
├── Models/
│   ├── ProjectType.swift
│   ├── ProjectStatus.swift
│   ├── WorkBlockState.swift
│   ├── SyncState.swift
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
├── Support/
│   ├── AppModelContainer.swift
│   └── SampleDataSeeder.swift
└── Views/
    ├── DashboardView.swift
    ├── CalendarPlaceholderView.swift
    ├── ProjectsPlaceholderView.swift
    ├── PlanPlaceholderView.swift
    └── LogPlaceholderView.swift
```

## Swift Playgrounds paste order

When copying files manually:

1. Add the four Enum files under `Models`.
2. Add the six SwiftData model files under `Models`.
3. Add `Support/AppModelContainer.swift`.
4. Add all Store files, starting with `ProjectStore`, `RawTaskStore`, `WorkBlockStore`, `LogStore`, and `DashboardStore`, then `AppStores`.
5. Add `Support/SampleDataSeeder.swift`.
6. Add all files under `Views`.
7. Add `ContentView.swift`.
8. Add `App.swift` last.

When using GitHub, download the repository archive and open `nouae_scheduler.swiftpm` directly.

## ModelContainer

`Support/AppModelContainer.swift` registers:
- `Project`
- `RawTask`
- `WorkBlock`
- `ProjectLog`
- `ProjectMemoSection`
- `NextAdjustment`

## iPad test steps

1. Download the latest repository archive from GitHub.
2. Open `nouae_scheduler.swiftpm` in Swift Playgrounds on iPad.
3. Run the app.
4. Confirm five tabs appear in order: Dashboard, Calendar, Projects, Plan, Log.
5. Open Dashboard and tap `샘플 데이터 생성`.
6. Confirm the Local Data counters update.
7. Open Projects and confirm `nou ae 개발` appears.
8. Open Plan and confirm one Inbox item and one WorkBlock appear.
9. Open Log and confirm one sample log appears.
10. Stop and run the app again. Confirm the sample data remains and is not duplicated.

## Expected notes

- Phase 1 does not request Calendar or Reminders permissions.
- Existing SwiftData files from an older experimental build can be incompatible. If launch fails immediately after downloading this Phase, delete the older local Playgrounds copy and open a fresh download.
- Phase 2 should add EventKit permissions and Project-to-Calendar creation on top of this stable local foundation.
