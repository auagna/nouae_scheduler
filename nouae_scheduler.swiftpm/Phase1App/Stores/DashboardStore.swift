import Combine
import Foundation
import SwiftData

struct DashboardSummary {
    let projects: Int
    let inboxTasks: Int
    let todayBlocks: Int
    let recentLogs: Int
}

@MainActor
final class DashboardStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func summary() throws -> DashboardSummary {
        let projects = try modelContext.fetch(FetchDescriptor<Project>())
        let tasks = try modelContext.fetch(FetchDescriptor<RawTask>())
        let blocks = try modelContext.fetch(FetchDescriptor<WorkBlock>())
        let logs = try modelContext.fetch(FetchDescriptor<ProjectLog>())
        return DashboardSummary(
            projects: projects.filter { $0.status != .archived }.count,
            inboxTasks: tasks.filter { !$0.isConvertedToBlock }.count,
            todayBlocks: blocks.filter { Calendar.current.isDateInToday($0.startAt) }.count,
            recentLogs: logs.count
        )
    }
}
