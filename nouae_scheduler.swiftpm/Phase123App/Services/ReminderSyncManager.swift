import EventKit
import Foundation
import SwiftData

struct ReminderListSource: Identifiable {
    let id: String
    let title: String
}

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

    func fetchReminderLists() async throws -> [ReminderListSource] {
        try await eventKit.requireReminderAccess()
        return eventKit.eventStore.calendars(for: .reminder)
            .map { ReminderListSource(id: $0.calendarIdentifier, title: $0.title) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func createReminderList(title: String) async throws -> ReminderListSource {
        try await eventKit.requireReminderAccess()
        if let existing = eventKit.eventStore.calendars(for: .reminder).first(where: { $0.title == title }) {
            return ReminderListSource(id: existing.calendarIdentifier, title: existing.title)
        }
        guard let source = preferredReminderSource() else { throw SyncError.sourceNotFound }
        let list = EKCalendar(for: .reminder, eventStore: eventKit.eventStore)
        list.title = title
        list.source = source
        do {
            try eventKit.eventStore.saveCalendar(list, commit: true)
        } catch {
            throw SyncError.reminderListCreationFailed
        }
        return ReminderListSource(id: list.calendarIdentifier, title: list.title)
    }

    func ensureBlockReminderList() async throws -> ReminderListSource {
        try await eventKit.requireReminderAccess()
        let settings = try syncSettings()

        if let identifier = settings.blockReminderListIdentifier,
           let existing = eventKit.eventStore.calendar(withIdentifier: identifier) {
            settings.blockReminderListTitle = existing.title
            settings.updatedAt = Date()
            try? context.save()
            return ReminderListSource(id: existing.calendarIdentifier, title: existing.title)
        }

        if let existing = eventKit.eventStore.calendars(for: .reminder).first(where: { $0.title == settings.blockReminderListTitle }) {
            settings.blockReminderListIdentifier = existing.calendarIdentifier
            settings.blockReminderListTitle = existing.title
            settings.updatedAt = Date()
            try? context.save()
            return ReminderListSource(id: existing.calendarIdentifier, title: existing.title)
        }

        let created = try await createReminderList(title: settings.blockReminderListTitle)
        settings.blockReminderListIdentifier = created.id
        settings.blockReminderListTitle = created.title
        settings.updatedAt = Date()
        try context.save()
        return created
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
            let targetList = try await reminderListForRawTask(task)
            if let identifier = task.reminderIdentifier,
               let existing = eventKit.eventStore.calendarItem(withIdentifier: identifier) as? EKReminder {
                reminder = existing
            } else {
                reminder = EKReminder(eventStore: eventKit.eventStore)
            }
            reminder.calendar = targetList
            reminder.title = task.title
            reminder.dueDateComponents = task.scheduledAt.map {
                Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: $0)
            }
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
        try await eventKit.requireReminderAccess()
        guard let identifier = task.reminderIdentifier,
              let reminder = eventKit.eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else { return }
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

    private func reminderListForRawTask(_ task: RawTask) async throws -> EKCalendar {
        if let projectId = task.projectId,
           let project = try context.fetch(FetchDescriptor<Project>()).first(where: { $0.id == projectId }) {
            if let identifier = project.reminderListIdentifier,
               let list = eventKit.eventStore.calendar(withIdentifier: identifier) {
                return list
            }

            if let area = try context.fetch(FetchDescriptor<ProjectArea>()).first(where: { $0.id == project.areaId }),
               let identifier = area.reminderListIdentifier,
               let list = eventKit.eventStore.calendar(withIdentifier: identifier) {
                project.reminderListIdentifier = identifier
                project.reminderListTitle = area.reminderListTitle
                try? context.save()
                return list
            }
        }

        let blockList = try await ensureBlockReminderList()
        guard let list = eventKit.eventStore.calendar(withIdentifier: blockList.id) else {
            throw SyncError.reminderCalendarNotFound
        }
        return list
    }

    private func syncSettings() throws -> AppSyncSettings {
        if let existing = try context.fetch(FetchDescriptor<AppSyncSettings>()).first {
            return existing
        }
        let settings = AppSyncSettings()
        context.insert(settings)
        try context.save()
        return settings
    }

    private func preferredReminderSource() -> EKSource? {
        eventKit.eventStore.sources.first { $0.sourceType == .calDAV && $0.title.localizedCaseInsensitiveContains("icloud") }
            ?? eventKit.eventStore.defaultCalendarForNewReminders()?.source
            ?? eventKit.eventStore.sources.first { $0.sourceType == .local }
    }
}
