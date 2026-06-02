# Phase 7 8 9 - Execution, Log and Dashboard

## Scope

The active Swift Playgrounds target remains `Phase123App`. No SwiftData entity fields were added, so an existing Phase 1 through 6 local store can continue loading.

## Execution flow

```text
planned -> inProgress -> completed
                    \-> delayed -> RawTask scheduled for tomorrow
                    \-> stopped
```

- A WorkBlock never starts automatically.
- When its start time arrives, Plan shows a start suggestion.
- Only tapping 시작 changes the block to `inProgress`.
- An in-progress block shows remaining time, Project and memo.
- When its end time passes, Plan offers 완료, 미룸 and 중단.
- 미룸 keeps the original WorkBlock as `delayed` and creates a new RawTask for tomorrow.
- 중단 keeps the WorkBlock as `stopped`.
- 완료 opens a Log editor as an optional follow-up. Closing it without saving creates no Log.
- Long-pressing a WorkBlock on the Day Board exposes the same manual state actions for correction and testing.

## Log

The Log tab now supports manual creation with:

- optional Project link
- optional WorkBlock link
- focus level from 1 to 5
- blocker tags
- blocker memo
- next adjustment
- short reflection

Saving a Project-linked Log with a next adjustment also creates the latest active `NextAdjustment` for that Project.

## Dashboard

Dashboard now shows:

- today's planned, in-progress, completed, delayed and stopped totals
- active Projects
- today's WorkBlocks
- delayed WorkBlocks
- active Next Adjustments
- recent Logs
- a calculated Closing Summary

## iPad Swift Playgrounds verification

1. Download the latest `nouae_scheduler.swiftpm` package and run it in Swift Playgrounds.
2. Open Plan and place a RawTask on today's Day Board. Choose a Project with an Apple Calendar link.
3. Place the block so its start time is now or slightly earlier and its end time is later.
4. Confirm that a start suggestion appears. Verify that it stays `planned` until 시작 is tapped.
5. Tap 시작 and confirm the remaining-time panel appears.
6. Use 완료. Confirm that the optional Log editor opens. Cancel once and verify no Log is created.
7. Complete another block and save a Log with focus level, blocker tag and next adjustment.
8. Open Log and confirm the saved entry appears.
9. Open the linked Project Dashboard and confirm the recent Log and Today Work state appear.
10. Long-press a planned WorkBlock and choose 미룸. Confirm the original block becomes `delayed` and does not immediately reappear in today's Inbox.
11. Open Apple Reminders and confirm a reminder for the delayed task was created with tomorrow's date.
12. Open Dashboard and confirm today's totals, delayed list, recent Log, active adjustment and Closing Summary update.

## Build note

The package build number is `9`. Calendar and Reminder permissions remain unchanged from Phase 4 through 6.
