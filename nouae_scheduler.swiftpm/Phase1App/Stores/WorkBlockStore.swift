import Combine
import Foundation
import SwiftData

@MainActor
final class WorkBlockStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    @discardableResult
    func createWorkBlock(title: String, projectId: UUID? = nil, rawTaskId: UUID? = nil, startAt: Date, endAt: Date) throws -> WorkBlock {
        let block = WorkBlock(title: title.trimmingCharacters(in: .whitespacesAndNewlines), projectId: projectId, rawTaskId: rawTaskId, startAt: startAt, endAt: endAt)
        modelContext.insert(block)
        try modelContext.save()
        return block
    }

    func fetchTodayBlocks() throws -> [WorkBlock] {
        let blocks = try modelContext.fetch(FetchDescriptor<WorkBlock>(sortBy: [SortDescriptor(\.startAt)]))
        return blocks.filter { Calendar.current.isDateInToday($0.startAt) }
    }

    func updateState(_ block: WorkBlock, state: WorkBlockState) throws {
        block.executionState = state
        block.progress = state == .completed ? 1 : block.progress
        block.updatedAt = Date()
        try modelContext.save()
    }
}
