import Combine

@MainActor
final class AppServices: ObservableObject {
    let eventKitManager: EventKitManager
    let calendarSyncManager: CalendarSyncManager

    init() {
        let eventKitManager = EventKitManager()
        self.eventKitManager = eventKitManager
        calendarSyncManager = CalendarSyncManager(eventKitManager: eventKitManager)
    }
}
