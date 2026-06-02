import Foundation

@MainActor
enum SampleDataSeeder {
    static func seed(using stores: AppStores) throws {
        guard try stores.projectStore.fetchProjects().isEmpty else { return }

        let project = try stores.projectStore.createProject(
            title: "nou ae 개발",
            type: .work,
            goal: "하루 루프 MVP 완성"
        )
        _ = try stores.rawTaskStore.createRawTask(
            title: "Phase 1 구조 점검",
            projectId: project.id
        )
        let start = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
        let end = Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
        _ = try stores.workBlockStore.createWorkBlock(
            title: "SwiftData 모델 확인",
            projectId: project.id,
            startAt: start,
            endAt: end
        )
        _ = try stores.logStore.createLog(
            projectId: project.id,
            focusLevel: 4,
            content: "Phase 1 샘플 로그"
        )
    }
}
