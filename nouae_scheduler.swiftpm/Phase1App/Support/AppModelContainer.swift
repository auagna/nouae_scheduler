import SwiftData

enum AppModelContainer {
    static func make(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            Project.self,
            RawTask.self,
            WorkBlock.self,
            ProjectLog.self,
            ProjectMemoSection.self,
            NextAdjustment.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
