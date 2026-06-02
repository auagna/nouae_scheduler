import SwiftData

@MainActor
final class DashboardStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    func projectCount() throws -> Int { try context.fetch(FetchDescriptor<Project>()).filter { $0.status != .archived }.count }
}
