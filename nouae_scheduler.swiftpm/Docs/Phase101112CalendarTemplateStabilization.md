# Phase 10 11 12 - Calendar, Templates and MVP Stabilization

## Scope

The active Swift Playgrounds target remains `Phase123App`. No SwiftData entity fields were added in these phases, so existing Phase 1 through 9 local data can continue loading.

## Phase 10 - Calendar View

Calendar tab is now a read-only flow view with:

- Month view
- Week view
- Day view
- Apple Calendar color display
- Project Calendar filter sheet
- Apple Calendar Event and local WorkBlock display
- Navigation from a Project-linked Calendar item into Project Dashboard

Calendar tab does not edit events. Planning, dragging, resizing and execution remain in Plan.

## Phase 11 - Project Templates

Project creation now generates Project Page sections from `ProjectType` through `TemplateDatabase`.

Every Project gets:

- 목표
- Inbox
- 메모
- 다음 조정
- 링크
- 리포트 메모

Project-type-specific sections are also added for study, work, exercise, creative, portfolio and personal projects.

Project Page sections can be added and edited from Project Dashboard.

## Phase 12 - Stabilization

Stability changes:

- Duplicate active Project titles are blocked because Project maps 1:1 to Apple Calendar.
- Creating a Project reuses an existing Apple Calendar with the same title instead of creating another duplicate calendar.
- Calendar filter selections persist with UserDefaults.
- Calendar and Reminder permission denial continues to show explicit Korean guidance.
- Local WorkBlocks remain visible in Calendar when sync has not completed.
- Sample data can be removed from Dashboard without deleting user-created projects.
- Build number is `12`.

## iPad Swift Playgrounds verification

1. Download the latest `nouae_scheduler.swiftpm` package and run it in Swift Playgrounds.
2. Open Calendar and allow Calendar full access.
3. Switch between Month, Week and Day.
4. Open the filter button and toggle Project Calendars on and off.
5. Confirm Apple Calendar colors appear next to events.
6. Create or sync a WorkBlock from Plan, then confirm it appears in Calendar.
7. Tap an event connected to a Project and confirm Project Dashboard opens.
8. Create a new Project of each type if needed and confirm Project Page template sections are generated.
9. Edit a Project Page section and add a new section.
10. Try creating a Project with the same active title. Confirm duplicate creation is blocked.
11. Use Dashboard MVP 관리 > 샘플 데이터 생성, then 샘플 데이터 제거. Confirm only the sample project is removed.
12. Deny Calendar or Reminder permission from iPad Settings and confirm the app shows permission guidance instead of crashing.

## Known MVP boundaries

- Calendar is view/filter/navigation only.
- Year view is excluded.
- Calendar event editing remains in Plan or Apple Calendar.
- AI API calls are not implemented; templates are local static defaults.
