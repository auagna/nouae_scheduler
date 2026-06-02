# Phase 4 5 6 - Plan and Sync

## Scope

The active Swift Playgrounds target remains `Phase123App`. The SwiftData schema is unchanged so an existing Phase 1 2 3 local store can continue loading.

Phase 4 adds Apple Reminders full-access permission and bidirectional RawTask synchronization. Phase 5 replaces the Plan placeholder with a split Inbox and Day Board. Phase 6 adds ten-minute snapped WorkBlock move and resize interactions plus three-second debounced Apple Calendar Event synchronization.

## Data flow

```text
Apple Reminder <-> RawTask -> WorkBlock <-> Apple Calendar Event
                         \-> Project Dashboard Today Work
```

- Apple Reminder values win when reminders are imported again.
- `reminderIdentifier` prevents duplicate RawTask imports.
- Converting a RawTask marks it converted and attempts to complete its linked reminder.
- WorkBlocks linked to a Project use that Project's Calendar identifier.
- WorkBlocks without a Project Calendar remain local.
- Event titles stay unchanged. No category text prefix is added.

## iPad Swift Playgrounds verification

1. Download the latest GitHub package and open `nouae_scheduler.swiftpm` in Swift Playgrounds.
2. Run the app and open Projects. Create a Project so it receives an Apple Calendar.
3. Add one item in Apple Reminders.
4. Open Plan and tap the refresh icon. Allow Reminders full access.
5. Confirm the reminder appears once in RawTask Inbox. Refresh again and confirm it is not duplicated.
6. Add another item with Quick Capture. Confirm it appears in Apple Reminders.
7. Tap a RawTask, select a Project and time, then tap 배치.
8. Confirm the WorkBlock appears on the Day Board and in the Project Dashboard 오늘 작업 section.
9. Wait three seconds and confirm an event with the same plain title appears in the Project Apple Calendar.
10. Drag the WorkBlock body to move it. Drag the top and bottom handles to resize it. Wait three seconds after each final adjustment and confirm the Calendar Event updates.
11. Edit the event time in Apple Calendar, reopen Plan, and confirm the linked WorkBlock refreshes to the Apple value.

## Permission notes

The package Info.plist already contains both iOS 17 full-access usage descriptions and legacy usage descriptions for Calendars and Reminders.

If access was denied earlier, allow Calendars and Reminders for nou ae in iPad Settings, then reopen the app.
