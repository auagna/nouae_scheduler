import SwiftData

@MainActor
final class AppStores: ObservableObject {
    let projectStore: ProjectStore
    let rawTaskStore: RawTaskStore
    let workBlockStore: WorkBlockStore
    let logStore: LogStore
    let dashboardStore: DashboardStore

    init(modelContext: ModelContext) {
        let projectStore = ProjectStore(modelContext: modelContext)
        let workBlockStore = WorkBlockStore(modelContext: modelContext)

        self.projectStore = projectStore
        self.rawTaskStore = RawTaskStore(modelContext: modelContext)
        self.workBlockStore = workBlockStore
        self.logStore = LogStore(modelContext: modelContext)
        self.dashboardStore = DashboardStore(
            modelContext: modelContext,
            projectStore: projectStore,
            workBlockStore: workBlockStore
        )
    }
}
