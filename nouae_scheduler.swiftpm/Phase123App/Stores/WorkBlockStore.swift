import Foundation
import SwiftData

@MainActor
final class WorkBlockStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func createWorkBlock(title: String, projectId: UUID?, startAt: Date, endAt: Date) throws -> WorkBlock { let block = WorkBlock(title: title, projectId: projectId, startAt: startAt, endAt: endAt); context.insert(block); try context.save(); return block }
    func fetchBlocksByProject(projectId: UUID) throws -> [WorkBlock] { try context.fetch(FetchDescriptor<WorkBlock>()).filter { $0.projectId == projectId } }
    func fetchTodayBlocksByProject(projectId: UUID) throws -> [WorkBlock] { try fetchBlocksByProject(projectId: projectId).filter { Calendar.current.isDateInToday($0.startAt) } }
    func calculateProjectProgress(blocks: [WorkBlock]) -> Double { blocks.isEmpty ? 0 : Double(blocks.filter { $0.executionState == .completed }.count) / Double(blocks.count) }
}
