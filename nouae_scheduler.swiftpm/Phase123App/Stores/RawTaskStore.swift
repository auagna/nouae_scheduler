import Foundation
import SwiftData

@MainActor
final class RawTaskStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func createRawTask(title: String, projectId: UUID? = nil, syncState: SyncState = .local) throws -> RawTask {
        let task = RawTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines), projectId: projectId, syncState: syncState)
        context.insert(task)
        try context.save()
        return task
    }

    func upsertImportedReminder(title: String, reminderIdentifier: String, scheduledAt: Date?) throws -> RawTask {
        if let task = try findByReminderIdentifier(reminderIdentifier) {
            task.title = title
            task.scheduledAt = scheduledAt
            task.syncState = .synced
            try context.save()
            return task
        }
        let task = RawTask(title: title, reminderIdentifier: reminderIdentifier, scheduledAt: scheduledAt, syncState: .synced)
        context.insert(task)
        try context.save()
        return task
    }

    func findByReminderIdentifier(_ identifier: String) throws -> RawTask? {
        try context.fetch(FetchDescriptor<RawTask>()).first { $0.reminderIdentifier == identifier }
    }

    func markConverted(_ task: RawTask, scheduledAt: Date) throws {
        task.isConvertedToBlock = true
        task.scheduledAt = scheduledAt
        try context.save()
    }

    func fetchInboxTasks() throws -> [RawTask] {
        try context.fetch(FetchDescriptor<RawTask>()).filter { !$0.isConvertedToBlock }
    }

    func fetchTasksByProject(projectId: UUID) throws -> [RawTask] {
        try context.fetch(FetchDescriptor<RawTask>()).filter { $0.projectId == projectId }
    }

    func fetchUnconvertedTasksByProject(projectId: UUID) throws -> [RawTask] {
        try fetchTasksByProject(projectId: projectId).filter { !$0.isConvertedToBlock }
    }
}
