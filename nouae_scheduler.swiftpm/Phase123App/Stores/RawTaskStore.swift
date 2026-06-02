import Foundation
import SwiftData

@MainActor
final class RawTaskStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func createRawTask(title: String, projectId: UUID? = nil) throws -> RawTask {
        let task = RawTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines), projectId: projectId)
        context.insert(task)
        try context.save()
        return task
    }
    func fetchTasksByProject(projectId: UUID) throws -> [RawTask] { try context.fetch(FetchDescriptor<RawTask>()).filter { $0.projectId == projectId } }
    func fetchUnconvertedTasksByProject(projectId: UUID) throws -> [RawTask] { try fetchTasksByProject(projectId: projectId).filter { !$0.isConvertedToBlock } }
}
