import Combine
import Foundation
import SwiftData

@MainActor
final class LogStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    @discardableResult
    func createLog(projectId: UUID? = nil, workBlockId: UUID? = nil, focusLevel: Int? = nil, content: String = "") throws -> ProjectLog {
        let log = ProjectLog(projectId: projectId, workBlockId: workBlockId, focusLevel: focusLevel, content: content)
        modelContext.insert(log)
        try modelContext.save()
        return log
    }

    func fetchRecentLogs(limit: Int = 10) throws -> [ProjectLog] {
        let logs = try modelContext.fetch(FetchDescriptor<ProjectLog>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        return Array(logs.prefix(limit))
    }
}
