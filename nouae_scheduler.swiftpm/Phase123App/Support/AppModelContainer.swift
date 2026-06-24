import SwiftData

enum AppModelContainer {
    static var schema: Schema {
        Schema([
            AppSyncSettings.self,
            ProjectArea.self,
            Project.self,
            RawTask.self,
            WorkBlock.self,
            ProjectLog.self,
            ProjectNote.self,
            ProjectBoardItem.self,
            ProjectMemoSection.self,
            NextAdjustment.self,
            ModuleInstance.self,
            ModulePermissionGrant.self,
            ModuleDraftRecord.self
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
