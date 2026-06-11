# nou ae TestFlight Readiness

This checkpoint keeps TestFlight preparation focused on stability, data safety, and the daily operating loop. Do not add new product features during this pass unless they remove a crash, data loss risk, or sync ambiguity.

## App Identity

- App name: `nou ae`
- Avoid: `NOU AE`, `Nou Ae`, `NOUAe`, `Nouae`
- Product definition: Personal Operating System
- Core loop: Observe -> Act -> Reflect -> Synthesize -> Become

## Permission Copy

- Calendar permission explains Area Calendar, BLOCK Calendar, and WorkBlock sync.
- Reminder permission explains Area Reminder List, BLOCK Reminder List, and RawTask Inbox sync.
- Denied permissions must remain recoverable from Settings.

## Required First Run Flow

1. Onboarding appears before Dashboard.
2. Calendar permission can be requested.
3. Reminder permission can be requested.
4. BLOCK Calendar can be created or verified.
5. BLOCK Reminder List can be created or verified.
6. First Area can be created.
7. First Project can be created inside an Area.
8. First RawTask can be captured.
9. First WorkBlock can be placed on the Plan HourGrid.
10. Completing onboarding opens Dashboard Mission Control.

## Screen QA

- Dashboard shows Mission Control, Life Pulse, Command Center, Intelligence, and Flow Matrix.
- Calendar supports Canvas, Month, Week, and Day.
- Calendar event detail supports view, edit, delete, and import as WorkBlock.
- Projects supports List and Notes modes.
- Project Dashboard shows Project Mission Control, Pulse, Today Work, Inbox, Thinking Space, Tracker, Logs, and Intelligence.
- Plan uses HourGrid Time Assembly Board with 10-minute snap.
- Plan unplan flow returns the original RawTask to Inbox when possible.
- Log supports Quick Log, mood tags, blocker tags, focus level, next adjustment, and timeline.
- Settings shows permissions, BLOCK status, Area sync status, pending sync, failed sync, Plan settings, and data controls.
- Prompt Export is available from Dashboard, Project Dashboard, Log, and Project Notes.

## Sync QA

- Area = Apple Calendar + Apple Reminder List.
- BLOCK = Apple Calendar + Apple Reminder List.
- Project belongs to Area and does not create its own Calendar/List.
- RawTask syncs to Apple Reminders without duplicate reminder identifiers.
- WorkBlock syncs to Apple Calendar without duplicate event identifiers.
- WorkBlock optional reminder sync does not create reminders unless enabled by the user.
- Project assignment moves Calendar/Reminder ownership to the Area target.
- Failed sync is visible.
- Pending sync can be retried.
- Missing Calendar or Reminder List is recoverable from Settings.

## Device QA

- iPhone portrait
- iPhone landscape where available
- iPad portrait
- iPad landscape
- Light mode
- Dark mode

## Performance QA

- Dashboard renders without visible stall.
- Calendar Canvas pan/zoom remains responsive.
- Month / Week / Day switching does not duplicate events.
- Plan drag and resize preview updates during the gesture.
- Sync operations do not block primary UI interactions.

## Data Safety

- Delete actions require confirmation.
- Archive is preferred over destructive deletion.
- Unplan avoids losing the original RawTask.
- Export remains available before large changes.
- Sample data removal is explicit.

## MVP Lock Rules

- Stop adding new features after this checkpoint.
- Allow only crash fixes, data loss fixes, sync fixes, UI hierarchy refinements, and copy corrections.
- Keep AI API integration out of MVP.
- Keep collaboration, file attachments, template market, advanced recurrence, social features, and medical mood analysis out of MVP.
