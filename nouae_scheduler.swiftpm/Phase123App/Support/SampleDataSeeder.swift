import Foundation
import SwiftData

@MainActor
enum SampleDataSeeder {
    private static let sampleProjectTitle = "nou ae 개발"

    static func seed(context: ModelContext, stores: AppStores) throws {
        guard try context.fetch(FetchDescriptor<Project>()).isEmpty else { return }
        let project = try stores.projectStore.createLocalProject(title: sampleProjectTitle, type: .work, status: .active, goal: "MVP 흐름 안정화")
        _ = try stores.rawTaskStore.createRawTask(title: "Project Dashboard 확인", projectId: project.id)
        let start = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
        _ = try stores.workBlockStore.createWorkBlock(title: "SwiftData 구조 점검", projectId: project.id, startAt: start, endAt: Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start)
        context.insert(ProjectLog(projectId: project.id, focusLevel: 4, content: "MVP 운영판 샘플 로그"))
        try stores.adjustmentStore.createAdjustment(projectId: project.id, content: "iPad 로드 안정성과 Calendar 동기화 확인")
        try context.save()
    }

    static func removeSampleData(context: ModelContext) throws {
        let sampleProjects = try context.fetch(FetchDescriptor<Project>()).filter { $0.title == sampleProjectTitle }
        let sampleProjectIds = Set(sampleProjects.map(\.id))
        guard !sampleProjectIds.isEmpty else { return }

        for task in try context.fetch(FetchDescriptor<RawTask>()).filter({ sampleProjectIds.contains($0.projectId ?? UUID()) }) {
            context.delete(task)
        }
        for block in try context.fetch(FetchDescriptor<WorkBlock>()).filter({ sampleProjectIds.contains($0.projectId ?? UUID()) }) {
            context.delete(block)
        }
        for log in try context.fetch(FetchDescriptor<ProjectLog>()).filter({ sampleProjectIds.contains($0.projectId ?? UUID()) }) {
            context.delete(log)
        }
        for section in try context.fetch(FetchDescriptor<ProjectMemoSection>()).filter({ sampleProjectIds.contains($0.projectId) }) {
            context.delete(section)
        }
        for adjustment in try context.fetch(FetchDescriptor<NextAdjustment>()).filter({ sampleProjectIds.contains($0.projectId ?? UUID()) }) {
            context.delete(adjustment)
        }
        for project in sampleProjects {
            context.delete(project)
        }
        try context.save()
    }
}
