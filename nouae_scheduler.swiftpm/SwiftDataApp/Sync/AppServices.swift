import Combine
import SwiftData

@MainActor
final class AppServices: ObservableObject {
    let eventKitManager: EventKitManager
    let calendarSyncManager: CalendarSyncManager
    let reminderSyncManager: ReminderSyncManager

    init(modelContext: ModelContext, stores: AppStores) {
        let eventKitManager = EventKitManager()
        self.eventKitManager = eventKitManager
        self.calendarSyncManager = CalendarSyncManager(
            eventKit: eventKitManager,
            projectStore: stores.projectStore,
            modelContext: modelContext
        )
        self.reminderSyncManager = ReminderSyncManager(
            eventKit: eventKitManager,
            rawTaskStore: stores.rawTaskStore,
            modelContext: modelContext
        )
    }
}
