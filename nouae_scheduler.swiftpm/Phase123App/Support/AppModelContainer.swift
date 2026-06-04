import SwiftData

enum AppModelContainer {
    static func make() throws -> ModelContainer {
        let schema = Schema([
            ProjectArea.self,
            Project.self,
            RawTask.self,
            WorkBlock.self,
            ProjectLog.self,
            ProjectMemoSection.self,
            NextAdjustment.self
        ])
        return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
    }
}
