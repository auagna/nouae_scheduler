import Foundation
import SwiftData

@MainActor
final class LogStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func createLog(projectId: UUID?, workBlockId: UUID?, focusLevel: Int?, blockerTags: [String], blockerNote: String, nextAdjustment: String, content: String) throws {
        let log = ProjectLog(
            projectId: projectId,
            workBlockId: workBlockId,
            focusLevel: focusLevel,
            blockerTags: blockerTags,
            blockerNote: blockerNote.trimmingCharacters(in: .whitespacesAndNewlines),
            nextAdjustment: nextAdjustment.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(log)
        if let projectId, !log.nextAdjustment.isEmpty {
            for item in try context.fetch(FetchDescriptor<NextAdjustment>()).filter({ $0.projectId == projectId }) {
                item.isActive = false
            }
            context.insert(NextAdjustment(projectId: projectId, content: log.nextAdjustment))
        }
        try context.save()
    }

    func fetchRecentLogsByProject(projectId: UUID, limit: Int = 3) throws -> [ProjectLog] {
        let logs = try context.fetch(FetchDescriptor<ProjectLog>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            .filter { $0.projectId == projectId }
        return Array(logs.prefix(limit))
    }
}
