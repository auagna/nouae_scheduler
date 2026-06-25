import Foundation
import SwiftData

@MainActor
final class RawTaskStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func createRawTask(title: String, projectId: UUID? = nil, scheduledAt: Date? = nil, syncState: SyncState = .local) throws -> RawTask {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw SyncError.invalidTitle }
        let task = RawTask(title: trimmedTitle, projectId: projectId, scheduledAt: scheduledAt, syncState: syncState)
        context.insert(task)
        try context.save()
        return task
    }

    @discardableResult
    func upsertImportedReminder(title: String, reminderIdentifier: String, scheduledAt: Date?) throws -> RawTask {
        if let existing = try context.fetch(FetchDescriptor<RawTask>()).first(where: { $0.reminderIdentifier == reminderIdentifier }) {
            existing.title = title
            existing.scheduledAt = scheduledAt
            existing.syncState = .synced
            try context.save()
            return existing
        }

        let task = RawTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "제목 없음" : title,
            reminderIdentifier: reminderIdentifier,
            scheduledAt: scheduledAt,
            syncState: .synced
        )
        context.insert(task)
        try context.save()
        return task
    }

    func assignProject(task: RawTask, projectId: UUID?) throws {
        task.projectId = projectId
        task.syncState = .pending
        try context.save()
    }

    func markConverted(task: RawTask, scheduledAt: Date?) throws {
        task.isConvertedToBlock = true
        task.scheduledAt = scheduledAt
        task.syncState = .pending
        try context.save()
    }

    func isVisibleInInbox(_ task: RawTask) -> Bool {
        !task.isConvertedToBlock
    }

    func fetchInboxTasks() throws -> [RawTask] {
        try context.fetch(FetchDescriptor<RawTask>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            .filter { isVisibleInInbox($0) }
    }

    func fetchTasksByProject(projectId: UUID) throws -> [RawTask] {
        try context.fetch(FetchDescriptor<RawTask>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            .filter { $0.projectId == projectId }
    }
}
