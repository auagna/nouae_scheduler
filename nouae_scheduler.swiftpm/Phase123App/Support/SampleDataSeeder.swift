import Foundation
import SwiftData

enum SampleDataSeeder {
    private static let sampleFlagKey = "nouae.sampleData.seeded"

    @MainActor
    static func seed(context: ModelContext, stores: AppStores) throws {
        guard !UserDefaults.standard.bool(forKey: sampleFlagKey) else { return }
        let area = try stores.projectAreaStore.createLocalArea(title: "Study")
        let project = try stores.projectStore.createProjectInArea(
            title: "기능사 공부",
            type: .study,
            status: .active,
            goal: "실기 시험 대비 루틴 만들기",
            area: area
        )
        let task = try stores.rawTaskStore.createRawTask(title: "도면 연습", projectId: project.id)
        let start = DateSnapper.date(on: Date(), minuteOfDay: 9 * 60)
        let end = DateSnapper.date(on: Date(), minuteOfDay: 9 * 60 + 40)
        _ = try stores.workBlockStore.convert(task: task, project: project, startAt: start, endAt: end)
        try stores.logStore.createLog(
            logType: .daily,
            projectId: project.id,
            workBlockId: nil,
            title: "Sample Log",
            focusLevel: 3,
            moodTags: ["집중"],
            blockerTags: [],
            blockerNote: "",
            nextAdjustment: "내일은 10분 단위로 더 작게 시작하기",
            content: "샘플 운영 흐름입니다."
        )
        UserDefaults.standard.set(true, forKey: sampleFlagKey)
    }

    @MainActor
    static func removeSampleData(context: ModelContext) throws {
        for task in try context.fetch(FetchDescriptor<RawTask>()).filter({ $0.title == "도면 연습" }) {
            context.delete(task)
        }
        for block in try context.fetch(FetchDescriptor<WorkBlock>()).filter({ $0.title == "도면 연습" }) {
            context.delete(block)
        }
        for log in try context.fetch(FetchDescriptor<ProjectLog>()).filter({ $0.title == "Sample Log" }) {
            context.delete(log)
        }
        for project in try context.fetch(FetchDescriptor<Project>()).filter({ $0.title == "기능사 공부" }) {
            context.delete(project)
        }
        for area in try context.fetch(FetchDescriptor<ProjectArea>()).filter({ $0.title == "Study" }) {
            context.delete(area)
        }
        try context.save()
        UserDefaults.standard.set(false, forKey: sampleFlagKey)
    }
}
