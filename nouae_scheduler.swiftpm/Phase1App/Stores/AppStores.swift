import Combine
import SwiftData

@MainActor
final class AppStores: ObservableObject {
    let projectStore: ProjectStore
    let rawTaskStore: RawTaskStore
    let workBlockStore: WorkBlockStore
    let logStore: LogStore
    let dashboardStore: DashboardStore

    init(modelContext: ModelContext) {
        projectStore = ProjectStore(modelContext: modelContext)
        rawTaskStore = RawTaskStore(modelContext: modelContext)
        workBlockStore = WorkBlockStore(modelContext: modelContext)
        logStore = LogStore(modelContext: modelContext)
        dashboardStore = DashboardStore(modelContext: modelContext)
    }
}
