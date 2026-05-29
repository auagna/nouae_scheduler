import Foundation
import SwiftData

@MainActor
final class RawTaskStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func createRawTask(
        title: String,
        projectId: UUID? = nil,
        reminderIdentifier: String? = nil,
        scheduledAt: Date? = nil
    ) throws -> RawTask {
        let task = RawTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            projectId: projectId,
            reminderIdentifier: reminderIdentifier,
            scheduledAt: scheduledAt,
            syncState: reminderIdentifier == nil ? .local : .synced
        )
        modelContext.insert(task)
        try save()
        return task
    }

    func assignProject(_ task: RawTask, projectId: UUID?) throws {
        task.projectId = projectId
        task.syncState = .pending
        try save()
    }

    @discardableResult
    func convertToWorkBlock(
        _ task: RawTask,
        startAt: Date,
        endAt: Date,
        calendarIdentifier: String? = nil,
        memo: String = ""
    ) throws -> WorkBlock {
        let block = WorkBlock(
            title: task.title,
            projectId: task.projectId,
            rawTaskId: task.id,
            startAt: DateSnapper.snapToTenMinutes(startAt),
            endAt: DateSnapper.snapToTenMinutes(endAt),
            calendarIdentifier: calendarIdentifier,
            memo: memo,
            syncState: .pending
        )
        modelContext.insert(block)
        task.isConvertedToBlock = true
        task.scheduledAt = startAt
        task.syncState = .pending
        try save()
        return block
    }

    func markConverted(_ task: RawTask) throws {
        task.isConvertedToBlock = true
        task.syncState = .pending
        try save()
    }

    func fetchInboxTasks() throws -> [RawTask] {
        let descriptor = FetchDescriptor<RawTask>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).filter { !$0.isConvertedToBlock }
    }

    func fetchTasksByProject(projectId: UUID) throws -> [RawTask] {
        try fetchInboxTasks().filter { $0.projectId == projectId }
    }

    func findTask(id: UUID) throws -> RawTask? {
        let descriptor = FetchDescriptor<RawTask>()
        return try modelContext.fetch(descriptor).first { $0.id == id }
    }

    private func save() throws {
        try modelContext.save()
    }
}
