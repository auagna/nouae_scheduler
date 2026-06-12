import Combine
import SwiftData

@MainActor
final class AppStores: ObservableObject {
    let projectAreaStore: ProjectAreaStore
    let projectStore: ProjectStore
    let rawTaskStore: RawTaskStore
    let workBlockStore: WorkBlockStore
    let logStore: LogStore
    let projectNoteStore: ProjectNoteStore
    let projectBoardStore: ProjectBoardStore
    let adjustmentStore: NextAdjustmentStore
    let dashboardStore: DashboardStore

    init(context: ModelContext) {
        projectAreaStore = ProjectAreaStore(context: context)
        projectStore = ProjectStore(context: context)
        rawTaskStore = RawTaskStore(context: context)
        workBlockStore = WorkBlockStore(context: context)
        logStore = LogStore(context: context)
        projectNoteStore = ProjectNoteStore(context: context)
        projectBoardStore = ProjectBoardStore(context: context)
        adjustmentStore = NextAdjustmentStore(context: context)
        dashboardStore = DashboardStore(context: context)
    }
}
