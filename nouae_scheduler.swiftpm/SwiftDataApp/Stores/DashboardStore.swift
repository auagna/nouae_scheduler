import Combine
import Foundation
import SwiftData

struct DashboardTodaySummary {
    let totalBlocks: Int
    let plannedBlocks: Int
    let inProgressBlocks: Int
    let completedBlocks: Int
    let delayedBlocks: Int
    let stoppedBlocks: Int
    let totalMinutes: Int
}

struct DashboardProjectSummary: Identifiable {
    let project: Project
    let totalBlocks: Int
    let todayBlocks: Int
    let totalMinutes: Int
    let todayMinutes: Int

    var id: UUID { project.id }
}

struct DashboardClosingSummary {
    let completedBlocks: Int
    let delayedBlocks: Int
    let stoppedBlocks: Int
    let completedMinutes: Int
}

@MainActor
final class DashboardStore: ObservableObject {
    private let modelContext: ModelContext
    private let projectStore: ProjectStore
    private let workBlockStore: WorkBlockStore

    init(
        modelContext: ModelContext,
        projectStore: ProjectStore,
        workBlockStore: WorkBlockStore
    ) {
        self.modelContext = modelContext
        self.projectStore = projectStore
        self.workBlockStore = workBlockStore
    }

    func todaySummary() throws -> DashboardTodaySummary {
        let blocks = try workBlockStore.fetchTodayBlocks()
        return DashboardTodaySummary(
            totalBlocks: blocks.count,
            plannedBlocks: blocks.filter { $0.executionState == .planned }.count,
            inProgressBlocks: blocks.filter { $0.executionState == .inProgress }.count,
            completedBlocks: blocks.filter { $0.executionState == .completed }.count,
            delayedBlocks: blocks.filter { $0.executionState == .delayed }.count,
            stoppedBlocks: blocks.filter { $0.executionState == .stopped }.count,
            totalMinutes: blocks.reduce(0) { $0 + $1.durationMinutes }
        )
    }

    func projectSummary(projectId: UUID) throws -> DashboardProjectSummary? {
        guard let project = try projectStore.findProject(id: projectId) else { return nil }
        let blocks = try workBlockStore.fetchBlocksByProject(projectId: projectId)
        let todayBlocks = blocks.filter { Calendar.current.isDateInToday($0.startAt) }
        return DashboardProjectSummary(
            project: project,
            totalBlocks: blocks.count,
            todayBlocks: todayBlocks.count,
            totalMinutes: blocks.reduce(0) { $0 + $1.durationMinutes },
            todayMinutes: todayBlocks.reduce(0) { $0 + $1.durationMinutes }
        )
    }

    func closingSummary() throws -> DashboardClosingSummary {
        let blocks = try workBlockStore.fetchTodayBlocks()
        return DashboardClosingSummary(
            completedBlocks: blocks.filter { $0.executionState == .completed }.count,
            delayedBlocks: blocks.filter { $0.executionState == .delayed }.count,
            stoppedBlocks: blocks.filter { $0.executionState == .stopped }.count,
            completedMinutes: blocks.filter { $0.executionState == .completed }.reduce(0) { $0 + $1.durationMinutes }
        )
    }

    func activeProjects() throws -> [Project] {
        try projectStore.fetchActiveProjects()
    }

    func delayedTasks() throws -> [WorkBlock] {
        try workBlockStore.delayedTasks()
    }

    func activeAdjustments() throws -> [NextAdjustment] {
        let descriptor = FetchDescriptor<NextAdjustment>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).filter(\.isActive)
    }
}
