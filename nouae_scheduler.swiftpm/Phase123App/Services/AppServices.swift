import Combine
import SwiftData

@MainActor
final class AppServices: ObservableObject {
    let eventKit: EventKitManager
    let calendarSync: CalendarSyncManager
    let reminderSync: ReminderSyncManager

    init(context: ModelContext, stores: AppStores) {
        let eventKit = EventKitManager()
        self.eventKit = eventKit
        calendarSync = CalendarSyncManager(eventKit: eventKit, context: context)
        reminderSync = ReminderSyncManager(eventKit: eventKit, context: context, rawTaskStore: stores.rawTaskStore)
    }
}
