import Foundation
import SwiftData

struct DashboardSnapshot {
    let planned: Int
    let inProgress: Int
    let completed: Int
    let activeProjects: [Project]
    let todayBlocks: [WorkBlock]
    let delayedBlocks: [WorkBlock]
    let recentAdjustments: [NextAdjustment]
    let recentLogs: [ProjectLog]

    var closingSummary: String {
        let delayedText = delayedBlocks.isEmpty ? "미룬 작업은 없습니다." : "미룬 작업은 \(delayedBlocks.count)개입니다."
        return "오늘 WorkBlock \(todayBlocks.count)개 중 \(completed)개를 완료했습니다. 진행 중 \(inProgress)개, 예정 \(planned)개이며 \(delayedText)"
    }
}

@MainActor
final class DashboardStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func projectCount() throws -> Int {
        try context.fetch(FetchDescriptor<Project>()).filter { $0.status != .archived }.count
    }

    func snapshot(projects: [Project], blocks: [WorkBlock], logs: [ProjectLog], adjustments: [NextAdjustment]) -> DashboardSnapshot {
        let todayBlocks = blocks.filter { Calendar.current.isDateInToday($0.startAt) }
        return DashboardSnapshot(
            planned: todayBlocks.filter { $0.executionState == .planned }.count,
            inProgress: todayBlocks.filter { $0.executionState == .inProgress }.count,
            completed: todayBlocks.filter { $0.executionState == .completed }.count,
            activeProjects: projects.filter { $0.status == .active },
            todayBlocks: todayBlocks.sorted { $0.startAt < $1.startAt },
            delayedBlocks: blocks.filter { $0.executionState == .delayed }.sorted { $0.updatedAt > $1.updatedAt },
            recentAdjustments: Array(adjustments.filter { $0.isActive }.sorted { $0.createdAt > $1.createdAt }.prefix(4)),
            recentLogs: Array(logs.sorted { $0.createdAt > $1.createdAt }.prefix(4))
        )
    }
}
