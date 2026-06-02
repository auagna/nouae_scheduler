import Foundation
import SwiftData

@MainActor
enum SampleDataSeeder {
    static func seed(context: ModelContext, stores: AppStores) throws {
        guard try context.fetch(FetchDescriptor<Project>()).isEmpty else { return }
        let project = try stores.projectStore.createLocalProject(title: "nou ae 개발", type: .work, status: .active, goal: "Phase 1 2 3 안정화")
        _ = try stores.rawTaskStore.createRawTask(title: "Project Dashboard 확인", projectId: project.id)
        let start = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
        _ = try stores.workBlockStore.createWorkBlock(title: "SwiftData 구조 점검", projectId: project.id, startAt: start, endAt: Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start)
        context.insert(ProjectLog(projectId: project.id, focusLevel: 4, content: "Phase 3 운영판 샘플 로그"))
        try stores.adjustmentStore.createAdjustment(projectId: project.id, content: "다음 단계 전에 iPad 로드 안정성 확인")
        try context.save()
    }
}
