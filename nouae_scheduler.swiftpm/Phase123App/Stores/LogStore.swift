import SwiftData

@MainActor
final class LogStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    func fetchRecentLogsByProject(projectId: UUID, limit: Int = 3) throws -> [ProjectLog] { let logs = try context.fetch(FetchDescriptor<ProjectLog>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])).filter { $0.projectId == projectId }; return Array(logs.prefix(limit)) }
}
