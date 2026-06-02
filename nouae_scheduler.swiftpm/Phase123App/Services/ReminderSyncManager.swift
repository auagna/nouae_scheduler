import EventKit
import Foundation
import SwiftData

@MainActor
final class ReminderSyncManager {
    private let eventKit: EventKitManager
    private let context: ModelContext
    private let rawTaskStore: RawTaskStore

    init(eventKit: EventKitManager, context: ModelContext, rawTaskStore: RawTaskStore) {
        self.eventKit = eventKit
        self.context = context
        self.rawTaskStore = rawTaskStore
    }

    func importInboxReminders() async throws -> Int {
        try await eventKit.requireReminderAccess()
        let reminders = await fetchIncompleteReminders()
        for reminder in reminders {
            let title = reminder.title ?? "제목 없음"
            let scheduledAt = reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
            _ = try rawTaskStore.upsertImportedReminder(
                title: title,
                reminderIdentifier: reminder.calendarItemIdentifier,
                scheduledAt: scheduledAt
            )
        }
        return reminders.count
    }

    func exportRawTask(_ task: RawTask) async throws {
        task.syncState = .syncing
        try? context.save()
        do {
            try await eventKit.requireReminderAccess()
            let reminder: EKReminder
            if let identifier = task.reminderIdentifier,
               let existing = eventKit.eventStore.calendarItem(withIdentifier: identifier) as? EKReminder {
                reminder = existing
            } else {
                guard let calendar = eventKit.eventStore.defaultCalendarForNewReminders() else {
                    throw SyncError.reminderCalendarNotFound
                }
                reminder = EKReminder(eventStore: eventKit.eventStore)
                reminder.calendar = calendar
            }
            reminder.title = task.title
            try eventKit.eventStore.save(reminder, commit: true)
            task.reminderIdentifier = reminder.calendarItemIdentifier
            task.syncState = .synced
            try context.save()
        } catch {
            task.syncState = .failed
            try? context.save()
            throw error
        }
    }

    func markReminderCompleted(for task: RawTask) async throws {
        guard let identifier = task.reminderIdentifier,
              let reminder = eventKit.eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else { return }
        try await eventKit.requireReminderAccess()
        reminder.isCompleted = true
        try eventKit.eventStore.save(reminder, commit: true)
    }

    private func fetchIncompleteReminders() async -> [EKReminder] {
        let predicate = eventKit.eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )
        return await withCheckedContinuation { continuation in
            _ = eventKit.eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
}
