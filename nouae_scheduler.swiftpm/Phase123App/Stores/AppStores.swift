import Combine
import SwiftData

@MainActor
final class AppStores: ObservableObject {
    let projectStore: ProjectStore
    let rawTaskStore: RawTaskStore
    let workBlockStore: WorkBlockStore
    let logStore: LogStore
    let adjustmentStore: NextAdjustmentStore

    init(context: ModelContext) {
        projectStore = ProjectStore(context: context)
        rawTaskStore = RawTaskStore(context: context)
        workBlockStore = WorkBlockStore(context: context)
        logStore = LogStore(context: context)
        adjustmentStore = NextAdjustmentStore(context: context)
    }
}
