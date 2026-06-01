# nou ae SwiftData Foundation

## Active Target

`Package.swift` uses `SwiftDataApp` as the active executable target path.

## File Structure

```text
nouae_scheduler.swiftpm/
├── Package.swift
├── Info.plist
├── SwiftDataApp/
│   ├── App.swift
│   ├── Models/
│   │   ├── Enums.swift
│   │   ├── Project.swift
│   │   ├── RawTask.swift
│   │   ├── WorkBlock.swift
│   │   ├── ProjectLog.swift
│   │   ├── ProjectMemoSection.swift
│   │   └── NextAdjustment.swift
│   ├── Stores/
│   │   ├── AppStores.swift
│   │   ├── ProjectStore.swift
│   │   ├── RawTaskStore.swift
│   │   ├── WorkBlockStore.swift
│   │   ├── LogStore.swift
│   │   └── DashboardStore.swift
│   ├── Support/
│   │   ├── AppModelContainer.swift
│   │   ├── DateSnapper.swift
│   │   └── SampleDataSeeder.swift
│   └── Views/
│       └── FoundationRootView.swift
└── Docs/
    └── SwiftDataFoundation.md
```

## Swift Playgrounds Paste Order

When rebuilding manually in Swift Playgrounds, add files in this order:

1. `Models/Enums.swift`
2. `Models/Project.swift`
3. `Models/RawTask.swift`
4. `Models/WorkBlock.swift`
5. `Models/ProjectLog.swift`
6. `Models/ProjectMemoSection.swift`
7. `Models/NextAdjustment.swift`
8. `Support/DateSnapper.swift`
9. `Stores/ProjectStore.swift`
10. `Stores/RawTaskStore.swift`
11. `Stores/WorkBlockStore.swift`
12. `Stores/LogStore.swift`
13. `Stores/DashboardStore.swift`
14. `Stores/AppStores.swift`
15. `Support/AppModelContainer.swift`
16. `Support/SampleDataSeeder.swift`
17. `Views/FoundationRootView.swift`
18. `App.swift`

## ModelContainer

`AppModelContainer.make()` registers these SwiftData models:

- `Project`
- `RawTask`
- `WorkBlock`
- `ProjectLog`
- `ProjectMemoSection`
- `NextAdjustment`

## Local Verification

1. Open the `.swiftpm` package in iPad Swift Playgrounds.
2. Run the app.
3. Open the `Data` tab.
4. Tap `Create Sample Data` once.
5. Confirm that Projects, RawTasks, WorkBlocks, Logs, Memo Sections, and Next Adjustments counts increase.
6. Add a title in `Quick RawTask` and tap `Add RawTask`.
7. Close and reopen the app.
8. Confirm that SwiftData records remain available.

## Store Rules

- Project creation inserts the default sections: `목표`, `Inbox`, `메모`, `다음 조정`.
- Projects are archived instead of deleted.
- RawTasks can be created with only a title.
- Converting a RawTask creates a WorkBlock and marks the task as converted.
- WorkBlock time updates snap to ten-minute increments by default.
- Logs are only created explicitly by the user.
- Closing report values are calculated by `DashboardStore`; there is no Closing Report entity.
- EventKit synchronization is intentionally deferred to the next step.
