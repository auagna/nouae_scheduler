import Foundation
import SwiftData

@MainActor
enum SampleDataSeeder {
    static func seedIfNeeded(modelContext: ModelContext) throws {
        let existingProjects = try modelContext.fetch(FetchDescriptor<Project>())
        guard existingProjects.isEmpty else { return }

        let projectStore = ProjectStore(modelContext: modelContext)
        let rawTaskStore = RawTaskStore(modelContext: modelContext)
        let workBlockStore = WorkBlockStore(modelContext: modelContext)
        let logStore = LogStore(modelContext: modelContext)

        let study = try projectStore.createProject(
            title: "nou ae 구조 설계",
            type: .study,
            status: .active,
            goal: "SwiftData 기반 로컬 데이터 구조를 안정화한다."
        )

        let exercise = try projectStore.createProject(
            title: "주 3회 운동",
            type: .exercise,
            status: .planning,
            goal: "짧더라도 꾸준히 움직인다."
        )

        let rawTask = try rawTaskStore.createRawTask(
            title: "Store 메서드 점검",
            projectId: study.id
        )

        _ = try rawTaskStore.createRawTask(
            title: "다음 운동 시간 정하기",
            projectId: exercise.id
        )

        let startAt = DateSnapper.snapToTenMinutes(Date())
        let endAt = Calendar.current.date(byAdding: .minute, value: 50, to: startAt) ?? startAt
        let block = try workBlockStore.createWorkBlock(
            title: rawTask.title,
            projectId: study.id,
            rawTaskId: rawTask.id,
            startAt: startAt,
            endAt: endAt,
            memo: "SwiftData 샘플 WorkBlock"
        )
        try workBlockStore.updateProgress(block, progress: 0.4)

        _ = try logStore.createLog(
            projectId: study.id,
            workBlockId: block.id,
            focusLevel: 4,
            blockerTags: ["구조"],
            blockerNote: "UI보다 Store 경계를 먼저 고정한다.",
            nextAdjustment: "EventKit 동기화 계층은 다음 단계에서 분리한다.",
            content: "SwiftData 모델과 Store 샘플 데이터를 생성했다."
        )

        modelContext.insert(
            NextAdjustment(
                projectId: study.id,
                content: "EventKit 동기화 계층을 Store 바깥 서비스로 추가한다."
            )
        )
        try modelContext.save()
    }
}
