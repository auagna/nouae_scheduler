import Combine
import Foundation
import SwiftData

@MainActor
final class RawTaskStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    @discardableResult
    func createRawTask(title: String, projectId: UUID? = nil) throws -> RawTask {
        let task = RawTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines), projectId: projectId)
        modelContext.insert(task)
        try modelContext.save()
        return task
    }

    func fetchInboxTasks() throws -> [RawTask] {
        let tasks = try modelContext.fetch(FetchDescriptor<RawTask>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        return tasks.filter { !$0.isConvertedToBlock }
    }

    func assignProject(_ task: RawTask, projectId: UUID?) throws {
        task.projectId = projectId
        try modelContext.save()
    }

    func markConverted(_ task: RawTask, scheduledAt: Date) throws {
        task.isConvertedToBlock = true
        task.scheduledAt = scheduledAt
        try modelContext.save()
    }
}
