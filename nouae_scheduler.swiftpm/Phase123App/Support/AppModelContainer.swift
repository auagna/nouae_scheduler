import SwiftData

enum AppModelContainer {
    static var schema: Schema {
        Schema([
            AppSyncSettings.self,
            Routine.self,
            RoutineOccurrence.self,
            ProjectArea.self,
            Project.self,
            RawTask.self,
            WorkBlock.self,
            ProjectLog.self,
            ProjectNote.self,
            ProjectBoardItem.self,
            ProjectMemoSection.self,
            NextAdjustment.self
        ])
    }

    static func make() throws -> ModelContainer {
        let schema = Self.schema
        return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
    }

    static func makeInMemory() throws -> ModelContainer {
        let schema = Self.schema
        return try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
    }
}
