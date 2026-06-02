import Foundation
import SwiftData

@MainActor
final class NextAdjustmentStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    func createAdjustment(projectId: UUID, content: String) throws { for item in try fetchAdjustmentsByProject(projectId: projectId) { item.isActive = false }; context.insert(NextAdjustment(projectId: projectId, content: content)); try context.save() }
    func fetchActiveAdjustment(projectId: UUID) throws -> NextAdjustment? { try fetchAdjustmentsByProject(projectId: projectId).first { $0.isActive } }
    func fetchAdjustmentsByProject(projectId: UUID) throws -> [NextAdjustment] { try context.fetch(FetchDescriptor<NextAdjustment>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])).filter { $0.projectId == projectId } }
}
