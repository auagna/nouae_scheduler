import Foundation
import SwiftData

struct DashboardSummary {
    var planned: Int
    var inProgress: Int
    var completed: Int
    var delayed: Int
    var failedSync: Int
}

@MainActor
final class DashboardStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func todaySummary() throws -> DashboardSummary {
        let blocks = try context.fetch(FetchDescriptor<WorkBlock>())
            .filter { Calendar.current.isDate($0.startAt, inSameDayAs: Date()) }
        let tasks = try context.fetch(FetchDescriptor<RawTask>())
        return DashboardSummary(
            planned: blocks.filter { $0.executionState == .planned }.count,
            inProgress: blocks.filter { $0.executionState == .inProgress }.count,
            completed: blocks.filter { $0.executionState == .completed }.count,
            delayed: blocks.filter { $0.executionState == .delayed }.count,
            failedSync: blocks.filter { $0.syncState == .failed }.count + tasks.filter { $0.syncState == .failed }.count
        )
    }

    func nextAction() throws -> WorkBlock? {
        let now = Date()
        return try context.fetch(FetchDescriptor<WorkBlock>(sortBy: [SortDescriptor(\.startAt)]))
            .filter { $0.executionState == .planned && $0.endAt >= now }
            .first
    }

    func activeProjects() throws -> [Project] {
        try context.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
            .filter { $0.status == .active && $0.archivedAt == nil }
    }
}

@MainActor
final class NextAdjustmentStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func createAdjustment(projectId: UUID?, content: String) throws -> NextAdjustment {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SyncError.invalidTitle }
        if let projectId {
            for item in try context.fetch(FetchDescriptor<NextAdjustment>()).filter({ $0.projectId == projectId }) {
                item.isActive = false
            }
        }
        let adjustment = NextAdjustment(projectId: projectId, content: trimmed)
        context.insert(adjustment)
        try context.save()
        return adjustment
    }
}
