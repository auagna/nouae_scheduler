import Combine
import EventKit
import Foundation
import SwiftData

@MainActor
final class ReminderSyncManager: ObservableObject {
    private let eventKit: EventKitManager
    private let rawTaskStore: RawTaskStore
    private let modelContext: ModelContext

    @Published private(set) var lastErrorMessage: String?

    init(eventKit: EventKitManager, rawTaskStore: RawTaskStore, modelContext: ModelContext) {
        self.eventKit = eventKit
        self.rawTaskStore = rawTaskStore
        self.modelContext = modelContext
    }

    func exportRawTask(_ task: RawTask) async {
        do {
            try await eventKit.requireReminderAccess()
            guard let defaultCalendar = eventKit.eventStore.defaultCalendarForNewReminders() else {
                throw SyncError.missingReminderCalendar
            }

            let reminder: EKReminder
            if let identifier = task.reminderIdentifier,
               let existing = eventKit.eventStore.calendarItem(withIdentifier: identifier) as? EKReminder {
                reminder = existing
            } else {
                reminder = EKReminder(eventStore: eventKit.eventStore)
            }

            task.syncState = .syncing
            reminder.calendar = defaultCalendar
            reminder.title = task.title
            if let scheduledAt = task.scheduledAt {
                reminder.dueDateComponents = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: scheduledAt
                )
            } else {
                reminder.dueDateComponents = nil
            }
            try eventKit.eventStore.save(reminder, commit: true)

            task.reminderIdentifier = reminder.calendarItemIdentifier
            task.syncState = .synced
            try modelContext.save()
            lastErrorMessage = nil
        } catch {
            task.syncState = .failed
            try? modelContext.save()
            lastErrorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func importInboxReminders() async throws -> [RawTask] {
        try await eventKit.requireReminderAccess()
        let predicate = eventKit.eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )
        let reminders: [EKReminder] = await withCheckedContinuation { continuation in
            eventKit.eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }

        var tasks: [RawTask] = []
        for reminder in reminders {
            let task = try rawTaskStore.importReminder(
                title: reminder.title ?? "제목 없음",
                reminderIdentifier: reminder.calendarItemIdentifier,
                scheduledAt: reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
            )
            tasks.append(task)
        }
        lastErrorMessage = nil
        return tasks
    }
}
