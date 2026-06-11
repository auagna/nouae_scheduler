# nou ae MVP Rehearsal and Lock

This document is the MVP lock gate. After this point, avoid new features unless they directly fix crashes, data loss, duplicated sync, or unusable primary flows.

Core loop: Observe -> Act -> Reflect -> Synthesize -> Become.

## Daily Rehearsal

### Morning

1. Open Dashboard.
2. Confirm Mission Control appears.
3. Read Life Pulse.
4. Read Current Mission.
5. Identify Next Action.

Expected feeling: the user is piloting the day, not checking a todo list.

### Late Morning

1. Capture a RawTask quickly.
2. Assign it to a Project when clear.
3. Confirm Reminder sync or pending state.
4. Confirm it remains visible in Plan Inbox until placed.

Expected feeling: capture is fast and does not demand planning too early.

### Midday

1. Open Plan.
2. Place a RawTask on HourGrid.
3. Resize to a 10-minute snapped duration.
4. Confirm WorkBlock appears as one SwiftData block.
5. Confirm Apple Calendar receives one Event.

Expected feeling: time is assembled, not buried in a calendar editor.

### During Work

1. Start WorkBlock manually.
2. Confirm inProgress state.
3. Complete, delay, or stop the block.
4. Confirm delayed tasks return to the capture flow.

Expected feeling: nou ae assists execution but never forces it.

### Evening

1. Write a Quick Log in under one minute.
2. Select mood tags.
3. Select blocker tags.
4. Add nextAdjustment when useful.
5. Confirm Log appears in Dashboard and Project Dashboard.

Expected feeling: reflection is light, structured, and useful.

### Night

1. Check Dashboard Closing Summary.
2. Open Project Dashboard for the most active Project.
3. Add or review Project Notes.
4. Check Tracker signals.
5. Generate a Prompt Export if deeper review is needed.

Expected feeling: the day becomes observable and adjustable.

## Lock Questions

1. Is there a reason to open Dashboard every day?
2. Is RawTask capture fast enough?
3. Is Plan placement less annoying than manual calendar editing?
4. Does Dashboard feel like Mission Control?
5. Does Project Dashboard feel like a living operating panel?
6. Do Project Notes feel like a notebook rather than a task container?
7. Is Calendar event selection and editing natural?
8. Does sync feel visible and recoverable?
9. Can Log be written in under one minute?
10. Does Tracker show that behavior is accumulating?

## Fix Priority

1. Crash
2. Data loss
3. Duplicate Calendar Event or Reminder
4. Plan HourGrid alignment or resize failure
5. Calendar edit failure
6. Dashboard information overload
7. Project Dashboard information overload
8. Log input fatigue
9. Onboarding confusion

## MVP Lock Rules

- Stop adding new features.
- Keep only bug fixes, sync fixes, data safety fixes, and UI hierarchy refinements.
- Preserve `ProjectArea = Apple Calendar + Apple Reminder List`.
- Preserve `Project = operating unit inside Area`.
- Preserve `RawTask = Reminder-backed capture item`.
- Preserve `WorkBlock = Calendar-backed time block`.
- Preserve `Log = internal reflection data`.
- Preserve `Dashboard = Mission Control`.
- Preserve `Plan = HourGrid Time Assembly Board`.

## Final MVP Definition

The MVP is acceptable when a user can operate one real day:

- Capture loose tasks.
- Place tasks into time.
- Execute WorkBlocks intentionally.
- Sync with Apple Calendar and Reminders.
- Write a short Log.
- Review Dashboard and Project Dashboard.
- Use Project Notes for thinking.
- Export data or AI prompt text when needed.

The final product is not the completed checklist. The final product is the user becoming more aware, deliberate, and synthesized.
