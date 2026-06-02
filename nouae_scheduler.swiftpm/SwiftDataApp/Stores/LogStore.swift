import Combine
import Foundation
import SwiftData

@MainActor
final class LogStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func createLog(
        projectId: UUID? = nil,
        workBlockId: UUID? = nil,
        focusLevel: Int? = nil,
        blockerTags: [String] = [],
        blockerNote: String = "",
        nextAdjustment: String = "",
        content: String = ""
    ) throws -> ProjectLog {
        let log = ProjectLog(
            projectId: projectId,
            workBlockId: workBlockId,
            focusLevel: focusLevel,
            blockerTags: blockerTags,
            blockerNote: blockerNote,
            nextAdjustment: nextAdjustment,
            content: content
        )
        modelContext.insert(log)
        let trimmedAdjustment = nextAdjustment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAdjustment.isEmpty {
            modelContext.insert(NextAdjustment(projectId: projectId, content: trimmedAdjustment))
        }
        try save()
        return log
    }

    func fetchLogsByProject(projectId: UUID) throws -> [ProjectLog] {
        let descriptor = FetchDescriptor<ProjectLog>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).filter { $0.projectId == projectId }
    }

    func fetchRecentLogs(limit: Int = 20) throws -> [ProjectLog] {
        let descriptor = FetchDescriptor<ProjectLog>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return Array(try modelContext.fetch(descriptor).prefix(limit))
    }

    func fetchLogsByDate(_ date: Date) throws -> [ProjectLog] {
        let interval = DateSnapper.dayInterval(for: date)
        let descriptor = FetchDescriptor<ProjectLog>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).filter { log in
            log.createdAt >= interval.start && log.createdAt < interval.end
        }
    }

    private func save() throws { try modelContext.save() }
}
