#if canImport(AppIntents)
import AppIntents
import Foundation
import SwiftData

struct CaptureRawTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Capture RawTask"
    static let description = IntentDescription("Capture a RawTask in nou ae.")
    static let openAppWhenRun = false

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Project")
    var project: ProjectEntity?

    @Parameter(title: "Due Date")
    var dueDate: Date?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await capture()
        return .result(dialog: "\(message)")
    }

    @MainActor
    private func capture() async throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NouAEIntentError.invalidInput }
        let stores = try IntentServiceContainer.shared.requireStores()
        let services = try IntentServiceContainer.shared.requireServices()
        let projectId = project.flatMap { UUID(uuidString: $0.id) }
        let task = try stores.rawTaskStore.createRawTask(title: trimmed, projectId: projectId, scheduledAt: dueDate, syncState: .pending)
        do {
            try await services.reminderSync.exportRawTask(task)
        } catch {
            task.syncState = .pending
            try? IntentServiceContainer.shared.requireContext().save()
        }
        if let project {
            return "'\(trimmed)'을 '\(project.title)'에 추가했습니다."
        }
        return "'\(trimmed)'을 Inbox에 추가했습니다."
    }
}

struct ShowNextActionIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Next Action"
    static let description = IntentDescription("Show the next executable action in nou ae.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await nextActionMessage()
        return .result(dialog: "\(message)")
    }

    @MainActor
    private func nextActionMessage() throws -> String {
        let context = try IntentServiceContainer.shared.requireContext()
        if let focus = try context.fetch(FetchDescriptor<WorkBlock>()).first(where: { $0.executionState == .inProgress }) {
            return "현재 진행 중인 작업은 '\(focus.title)'입니다."
        }
        if let next = try IntentServiceContainer.shared.requireStores().dashboardStore.nextAction() {
            return "다음 행동은 '\(next.title)'입니다. \(next.startAt.formatted(date: .omitted, time: .shortened))에 시작합니다."
        }
        if let task = try context.fetch(FetchDescriptor<RawTask>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])).first(where: { !$0.isConvertedToBlock }) {
            return "아직 배치되지 않은 다음 RawTask는 '\(task.title)'입니다."
        }
        return "현재 실행할 다음 작업이 없습니다."
    }
}

struct StartRoutineIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Routine"
    static let description = IntentDescription("Start a Routine occurrence in nou ae.")
    static let openAppWhenRun = false

    @Parameter(title: "Routine")
    var routine: RoutineEntity

    @Parameter(title: "Date")
    var date: Date?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await startRoutine()
        return .result(dialog: "\(message)")
    }

    @MainActor
    private func startRoutine() async throws -> String {
        guard let routineId = UUID(uuidString: routine.id) else { throw NouAEIntentError.entityNotFound }
        let stores = try IntentServiceContainer.shared.requireStores()
        let services = try IntentServiceContainer.shared.requireServices()
        guard let value = stores.routineStore.routines.first(where: { $0.id == routineId }) else {
            throw NouAEIntentError.entityNotFound
        }
        guard value.isActive, value.archivedAt == nil else { throw NouAEIntentError.routineDisabled }
        let targetDate = date ?? Date()
        let occurrence = stores.routineStore.ensureOccurrence(for: value, on: targetDate)
        if occurrence.state == .completed { throw NouAEIntentError.routineAlreadyCompleted }
        let result = try stores.routineStore.materializeRoutine(value, on: targetDate)
        if result.block.executionState != .inProgress && result.block.executionState != .completed {
            try stores.workBlockStore.start(block: result.block)
        }
        services.calendarSync.scheduleSync(block: result.block)
        return "'\(value.title)' Routine을 시작했습니다."
    }
}

struct QuickLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Log"
    static let description = IntentDescription("Write a short reflection log in nou ae.")
    static let openAppWhenRun = false

    @Parameter(title: "Project")
    var project: ProjectEntity?

    @Parameter(title: "Reflection")
    var reflection: String?

    @Parameter(title: "Focus Level")
    var focusLevel: Int?

    @Parameter(title: "Mood")
    var mood: String?

    @Parameter(title: "Blocker")
    var blocker: String?

    @Parameter(title: "Next Adjustment")
    var nextAdjustment: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await writeLog()
        return .result(dialog: "\(message)")
    }

    @MainActor
    private func writeLog() throws -> String {
        let content = reflection?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let moodValue = mood?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let blockerValue = blocker?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let adjustment = nextAdjustment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.isEmpty || !moodValue.isEmpty || !blockerValue.isEmpty || !adjustment.isEmpty else {
            return "기록할 내용이 없습니다."
        }

        let allowedMoods = Set(LogTaxonomy.moodGroups.flatMap { $0.tags })
        let allowedBlockers = Set(LogTaxonomy.blockerGroups.flatMap { $0.tags })
        let moodTags = moodValue.isEmpty ? [] : [allowedMoods.contains(moodValue) ? moodValue : "기타"]
        let blockerTags = blockerValue.isEmpty ? [] : [allowedBlockers.contains(blockerValue) ? blockerValue : "기타"]
        let projectId = project.flatMap { UUID(uuidString: $0.id) }
        try IntentServiceContainer.shared.requireStores().logStore.createLog(
            logType: .daily,
            projectId: projectId,
            workBlockId: nil,
            title: "Quick Log",
            focusLevel: focusLevel,
            moodTags: moodTags,
            blockerTags: blockerTags,
            blockerNote: blockerValue,
            nextAdjustment: adjustment,
            content: content
        )
        return "Log를 기록했습니다."
    }
}

struct OpenProjectIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Project"
    static let openAppWhenRun = true

    @Parameter(title: "Project")
    var project: ProjectEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await MainActor.run {
            guard !project.isArchived, let id = UUID(uuidString: project.id) else { throw NouAEIntentError.projectArchived }
            AppNavigationRouter.shared.openProject(id: id)
        }
        return .result(dialog: "'\(project.title)' Project를 엽니다.")
    }
}

struct OpenPlanIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Plan"
    static let openAppWhenRun = true

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Project")
    var project: ProjectEntity?

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppNavigationRouter.shared.openPlan(date: date, projectId: project.flatMap { UUID(uuidString: $0.id) })
        }
        return .result()
    }
}

struct OpenLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Log"
    static let openAppWhenRun = true

    @Parameter(title: "Project")
    var project: ProjectEntity?

    @Parameter(title: "Quick Log Mode")
    var quickLogMode: Bool

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppNavigationRouter.shared.openLog(projectId: project.flatMap { UUID(uuidString: $0.id) }, quickMode: quickLogMode)
        }
        return .result()
    }
}

struct OpenCalendarIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Calendar"
    static let openAppWhenRun = true

    @Parameter(title: "Date")
    var date: Date?

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppNavigationRouter.shared.openCalendar(date: date)
        }
        return .result()
    }
}

struct RunModuleActionIntent: AppIntent {
    static let title: LocalizedStringResource = "Run Module Action"
    static let description = IntentDescription("Run a safe installed Module action in nou ae.")
    static let openAppWhenRun = false

    @Parameter(title: "Module")
    var module: ShortcutModuleEntity

    @Parameter(title: "Action")
    var action: ShortcutModuleActionEntity

    @Parameter(title: "Project")
    var project: ProjectEntity?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await runAction()
        return .result(dialog: "\(message)")
    }

    @MainActor
    private func runAction() async throws -> String {
        let container = IntentServiceContainer.shared
        let context = try container.requireContext()
        let stores = try container.requireStores()
        let actionType = ModuleActionType(rawValue: action.actionIdentifier)
        guard action.moduleIdentifier == module.id, let actionType else { throw NouAEIntentError.unsupportedAction }
        guard let manifest = stores.moduleRegistry.module(for: module.id), manifest.isShortcutEligible else {
            throw NouAEIntentError.moduleDisabled
        }
        let grants = try context.fetch(FetchDescriptor<ModulePermissionGrant>())
        let permissionStore = ModulePermissionStore(grants: grants)
        guard permissionStore.hasRequiredCapabilities(for: manifest) else {
            throw NouAEIntentError.modulePermissionDenied
        }
        let moduleContext = ModuleContext(
            moduleIdentifier: module.id,
            currentDate: Date(),
            selectedAreaId: nil,
            selectedProjectId: project.flatMap { UUID(uuidString: $0.id) },
            currentPlacement: .settingsSection,
            projects: try context.fetch(FetchDescriptor<Project>()),
            tasks: try context.fetch(FetchDescriptor<RawTask>()),
            workBlocks: try context.fetch(FetchDescriptor<WorkBlock>()),
            logs: try context.fetch(FetchDescriptor<ProjectLog>()),
            routines: stores.routineStore.routines,
            permissionStore: permissionStore,
            actionRouter: container.moduleActionRouter
        )
        let moduleAction = ModuleAction(type: actionType, title: action.title)
        try await container.moduleActionRouter?.handle(moduleAction, context: moduleContext)
        return "'\(action.title)' Module Action을 실행했습니다."
    }
}

struct NouAEAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureRawTaskIntent(),
            phrases: [
                "\(.applicationName)에 할 일 추가",
                "\(.applicationName)에 작업 기록",
                "\(.applicationName)에 생각 추가",
                "Capture a task in \(.applicationName)",
                "Add a task to \(.applicationName)"
            ],
            shortTitle: "Capture",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: ShowNextActionIntent(),
            phrases: [
                "\(.applicationName) 다음 작업 보여줘",
                "\(.applicationName)에서 다음 행동 확인",
                "Show my next action in \(.applicationName)"
            ],
            shortTitle: "Next Action",
            systemImageName: "arrow.right.circle"
        )
        AppShortcut(
            intent: StartRoutineIntent(),
            phrases: [
                "\(.applicationName)에서 루틴 시작",
                "\(.applicationName) 루틴 실행",
                "Start a routine in \(.applicationName)"
            ],
            shortTitle: "Start Routine",
            systemImageName: "repeat.circle"
        )
        AppShortcut(
            intent: QuickLogIntent(),
            phrases: [
                "\(.applicationName)에 로그 작성",
                "\(.applicationName)에 회고 기록",
                "Write a quick log in \(.applicationName)"
            ],
            shortTitle: "Quick Log",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: OpenProjectIntent(),
            phrases: [
                "\(.applicationName)에서 프로젝트 열기",
                "Open a project in \(.applicationName)"
            ],
            shortTitle: "Open Project",
            systemImageName: "folder"
        )
    }
}
#endif
