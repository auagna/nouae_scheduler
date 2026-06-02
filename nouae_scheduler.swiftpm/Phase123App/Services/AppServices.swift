import Combine

@MainActor
final class AppServices: ObservableObject {
    let eventKit: EventKitManager
    let calendarSync: CalendarSyncManager
    init() { let eventKit = EventKitManager(); self.eventKit = eventKit; calendarSync = CalendarSyncManager(eventKit: eventKit) }
}
