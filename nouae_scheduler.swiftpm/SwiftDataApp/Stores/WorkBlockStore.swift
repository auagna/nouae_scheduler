import Foundation
import SwiftData

@MainActor
final class WorkBlockStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func createWorkBlock(
        title: String,
        projectId: UUID? = nil,
        rawTaskId: UUID? = nil,
        startAt: Date,
        endAt: Date,
        calendarIdentifier: String? = nil,
        memo: String = ""
    ) throws -> WorkBlock {
        let block = WorkBlock(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            projectId: projectId,
            rawTaskId: rawTaskId,
            startAt: DateSnapper.snapToTenMinutes(startAt),
            endAt: DateSnapper.snapToTenMinutes(endAt),
            calendarIdentifier: calendarIdentifier,
            memo: memo,
            syncState: .pending
        )
        modelContext.insert(block)
        if let rawTaskId, let task = try findRawTask(id: rawTaskId) {
            task.isConvertedToBlock = true
            task.scheduledAt = block.startAt
            task.syncState = .pending
        }
        try save()
        return block
    }

    func updateTime(
        _ block: WorkBlock,
        startAt: Date,
        endAt: Date,
        snapToTenMinutes: Bool = true
    ) throws {
        block.startAt = snapToTenMinutes ? DateSnapper.snapToTenMinutes(startAt) : startAt
        block.endAt = snapToTenMinutes ? DateSnapper.snapToTenMinutes(endAt) : endAt
        if block.endAt <= block.startAt {
            block.endAt = Calendar.current.date(byAdding: .minute, value: 10, to: block.startAt) ?? block.startAt
        }
        block.updatedAt = Date()
        block.syncState = .pending
        try save()
    }

    func updateProgress(_ block: WorkBlock, progress: Double) throws {
        block.progress = min(max(progress, 0), 1)
        block.updatedAt = Date()
        try save()
    }

    func updateState(_ block: WorkBlock, state: WorkBlockState) throws {
        block.executionState = state
        block.updatedAt = Date()
        block.syncState = .pending
        if state == .completed { block.progress = 1 }
        try save()
    }

    func markCompleted(_ block: WorkBlock) throws {
        try updateState(block, state: .completed)
    }

    func markDelayed(_ block: WorkBlock) throws {
        try updateState(block, state: .delayed)
    }

    func markStopped(_ block: WorkBlock) throws {
        try updateState(block, state: .stopped)
    }

    func fetchTodayBlocks() throws -> [WorkBlock] {
        let interval = DateSnapper.dayInterval(for: Date())
        return try fetchBlocksForDateRange(from: interval.start, to: interval.end)
    }

    func fetchBlocksByProject(projectId: UUID) throws -> [WorkBlock] {
        let descriptor = FetchDescriptor<WorkBlock>(sortBy: [SortDescriptor(\.startAt, order: .reverse)])
        return try modelContext.fetch(descriptor).filter { $0.projectId == projectId }
    }

    func fetchBlocksForDateRange(from startDate: Date, to endDate: Date) throws -> [WorkBlock] {
        let descriptor = FetchDescriptor<WorkBlock>(sortBy: [SortDescriptor(\.startAt)])
        return try modelContext.fetch(descriptor).filter { block in
            block.startAt >= startDate && block.startAt < endDate
        }
    }

    func delayedTasks() throws -> [WorkBlock] {
        let descriptor = FetchDescriptor<WorkBlock>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try modelContext.fetch(descriptor).filter { $0.executionState == .delayed }
    }

    private func findRawTask(id: UUID) throws -> RawTask? {
        let descriptor = FetchDescriptor<RawTask>()
        return try modelContext.fetch(descriptor).first { $0.id == id }
    }

    private func save() throws {
        try modelContext.save()
    }
}
