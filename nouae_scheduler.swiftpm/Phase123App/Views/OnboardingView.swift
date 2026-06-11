import SwiftData
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var services: AppServices
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \ProjectArea.updatedAt, order: .reverse) private var areas: [ProjectArea]
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \RawTask.createdAt, order: .reverse) private var rawTasks: [RawTask]

    @AppStorage("nouae.onboarding.completed") private var hasCompletedOnboarding = false
    @AppStorage("nouae.onboarding.calendarPermission") private var hasRequestedCalendarPermission = false
    @AppStorage("nouae.onboarding.reminderPermission") private var hasRequestedReminderPermission = false
    @AppStorage("nouae.onboarding.blockCalendar") private var hasCreatedBlockCalendar = false
    @AppStorage("nouae.onboarding.blockReminderList") private var hasCreatedBlockReminderList = false
    @AppStorage("nouae.onboarding.firstArea") private var hasCreatedFirstArea = false
    @AppStorage("nouae.onboarding.firstProject") private var hasCreatedFirstProject = false
    @AppStorage("nouae.onboarding.firstRawTask") private var hasCreatedFirstRawTask = false
    @AppStorage("nouae.onboarding.firstWorkBlock") private var hasCreatedFirstWorkBlock = false

    @State private var step: OnboardingStep = .welcome
    @State private var areaTitle = "공부"
    @State private var projectTitle = "기능사 공부"
    @State private var rawTaskTitle = "도면 연습"
    @State private var selectedAreaId: UUID?
    @State private var selectedProjectId: UUID?
    @State private var message: String?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            AppScreenContainer(spacing: 20) {
                AppPageHeader(title: step.title, subtitle: step.subtitle) {
                    Button("Skip") {
                        hasCompletedOnboarding = true
                    }
                    .buttonStyle(.bordered)
                }

                ProgressView(value: Double(step.rawValue.advanced(by: 1)), total: Double(OnboardingStep.allCases.count))

                AppPanel(title: panelTitle, subtitle: panelSubtitle) {
                    stepContent
                }

                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                navigationButtons
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedAreaId = areas.first?.id
                selectedProjectId = projects.first?.id
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            WelcomeStepView()
        case .calendarPermission:
            CalendarPermissionStepView(isGranted: services.eventKit.hasFullAccess) {
                Task { await requestCalendarPermission() }
            }
        case .reminderPermission:
            ReminderPermissionStepView(isGranted: services.eventKit.hasReminderFullAccess) {
                Task { await requestReminderPermission() }
            }
        case .blockSetup:
            BlockSetupStepView(
                hasCalendar: hasCreatedBlockCalendar,
                hasReminderList: hasCreatedBlockReminderList,
                isWorking: isWorking
            ) {
                Task { await setupBlock() }
            }
        case .firstArea:
            FirstAreaStepView(title: $areaTitle, areas: areas, selectedAreaId: $selectedAreaId, isWorking: isWorking) {
                Task { await createFirstArea() }
            }
        case .firstProject:
            FirstProjectStepView(
                title: $projectTitle,
                selectedAreaId: $selectedAreaId,
                areas: areas,
                projects: projects,
                isWorking: isWorking
            ) {
                Task { await createFirstProject() }
            }
        case .firstRawTask:
            FirstRawTaskStepView(
                title: $rawTaskTitle,
                selectedProjectId: $selectedProjectId,
                projects: projects,
                isWorking: isWorking
            ) {
                Task { await createFirstRawTask() }
            }
        case .firstWorkBlock:
            FirstWorkBlockStepView(projects: projects, rawTasks: rawTasks, isWorking: isWorking) {
                Task { await createFirstWorkBlock() }
            }
        }
    }

    private var navigationButtons: some View {
        HStack {
            Button {
                movePrevious()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(step == .welcome)

            Spacer()

            Button {
                moveNext()
            } label: {
                Label(step == .firstWorkBlock ? "Start nou ae" : "Next", systemImage: "chevron.right")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var panelTitle: String {
        switch step {
        case .welcome: return "Observe → Act → Reflect → Synthesize → Become"
        case .calendarPermission: return "Calendar는 시간 저장소입니다."
        case .reminderPermission: return "Reminders는 Capture 저장소입니다."
        case .blockSetup: return "BLOCK은 임시 영역입니다."
        case .firstArea: return "삶의 영역을 하나 만듭니다."
        case .firstProject: return "Area 안에 Project를 만듭니다."
        case .firstRawTask: return "생각을 빠르게 붙잡습니다."
        case .firstWorkBlock: return "시간 위에 배치합니다."
        }
    }

    private var panelSubtitle: String {
        switch step {
        case .welcome:
            return "nou ae는 할 일을 체크하는 앱이 아니라, 하루와 프로젝트를 운영하고 기록하며 조정하는 앱입니다."
        case .calendarPermission:
            return "Area Calendar와 BLOCK Calendar를 만들고 WorkBlock을 Apple Calendar에 동기화합니다."
        case .reminderPermission:
            return "RawTask Inbox와 Area Reminder List, BLOCK Reminder List를 연결합니다."
        case .blockSetup:
            return "Project가 아직 정해지지 않은 시간 블록과 할 일이 잠시 들어가는 Calendar / Reminder List입니다."
        case .firstArea:
            return "예: 공부, 작업, 운동, 개인"
        case .firstProject:
            return "예: 기능사 공부, 포트폴리오, nou ae 개발"
        case .firstRawTask:
            return "제목만 입력하면 됩니다. 자세한 것은 Plan에서 배치할 때 정합니다."
        case .firstWorkBlock:
            return "09:00 row 안의 00, 10, 20 column처럼 10분 단위로 조립됩니다."
        }
    }

    private func movePrevious() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    private func moveNext() {
        guard step != .firstWorkBlock else {
            hasCompletedOnboarding = true
            return
        }
        if let next = OnboardingStep(rawValue: step.rawValue.advanced(by: 1)) {
            step = next
        }
    }

    private func requestCalendarPermission() async {
        await run {
            try await services.eventKit.requireCalendarAccess()
            hasRequestedCalendarPermission = true
            message = "Calendar 권한이 준비되었습니다."
        }
    }

    private func requestReminderPermission() async {
        await run {
            try await services.eventKit.requireReminderAccess()
            hasRequestedReminderPermission = true
            message = "Reminder 권한이 준비되었습니다."
        }
    }

    private func setupBlock() async {
        await run {
            _ = try await services.calendarSync.ensureBlockCalendar()
            hasCreatedBlockCalendar = true
            _ = try await services.reminderSync.ensureBlockReminderList()
            hasCreatedBlockReminderList = true
            message = "BLOCK Calendar와 BLOCK Reminder List가 준비되었습니다."
        }
    }

    private func createFirstArea() async {
        await run {
            let area = try await stores.projectAreaStore.createArea(
                title: areaTitle,
                calendarSyncManager: services.calendarSync,
                reminderSyncManager: services.reminderSync
            )
            selectedAreaId = area.id
            hasCreatedFirstArea = true
            message = "\(area.title) Area를 만들었습니다."
        }
    }

    private func createFirstProject() async {
        await run {
            let area = selectedAreaId.flatMap { id in areas.first { $0.id == id } } ?? areas.first
            let project = try stores.projectStore.createProjectInArea(
                title: projectTitle,
                type: .study,
                status: .active,
                goal: "첫 운영 흐름 만들기",
                area: area
            )
            try stores.projectNoteStore.ensureDefaultNotes(areaId: area?.id, projectId: project.id, projectTitle: project.title)
            selectedProjectId = project.id
            hasCreatedFirstProject = true
            message = "\(project.title) Project를 만들었습니다."
        }
    }

    private func createFirstRawTask() async {
        await run {
            let task = try stores.rawTaskStore.createRawTask(title: rawTaskTitle, projectId: selectedProjectId ?? projects.first?.id)
            try? await services.reminderSync.exportRawTask(task)
            hasCreatedFirstRawTask = true
            message = "\(task.title) RawTask를 만들었습니다."
        }
    }

    private func createFirstWorkBlock() async {
        await run {
            let project = selectedProjectId.flatMap { id in projects.first { $0.id == id } } ?? projects.first
            let task: RawTask
            if let existingTask = rawTasks.first(where: { !$0.isConvertedToBlock }) {
                task = existingTask
            } else {
                task = try stores.rawTaskStore.createRawTask(title: rawTaskTitle, projectId: project?.id)
            }

            let startMinute = 540
            let endMinute = 580
            let startAt = DateSnapper.date(on: Date(), minuteOfDay: startMinute)
            let endAt = DateSnapper.date(on: Date(), minuteOfDay: endMinute)
            let block = try stores.workBlockStore.convert(task: task, project: project, startAt: startAt, endAt: endAt)
            services.calendarSync.scheduleSync(block: block)
            hasCreatedFirstWorkBlock = true
            message = "\(block.title) WorkBlock을 09:00에 배치했습니다."
        }
    }

    private func run(_ operation: @escaping () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await operation()
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct WelcomeStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The final product is not the completed checklist.")
                .font(.headline)
            Text("The final product is the user becoming more aware, deliberate, and synthesized.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            conceptRows
        }
    }

    private var conceptRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            ConceptRow(term: "Dashboard", description: "Mission Control")
            ConceptRow(term: "Plan", description: "시간 조립판")
            ConceptRow(term: "Log", description: "짧은 회고")
        }
    }
}

private struct CalendarPermissionStepView: View {
    let isGranted: Bool
    let onRequest: () -> Void

    var body: some View {
        PermissionStepBody(
            isGranted: isGranted,
            symbolName: "calendar",
            grantedText: "Calendar 접근이 준비되었습니다.",
            requestText: "Calendar 권한 요청",
            onRequest: onRequest
        )
    }
}

private struct ReminderPermissionStepView: View {
    let isGranted: Bool
    let onRequest: () -> Void

    var body: some View {
        PermissionStepBody(
            isGranted: isGranted,
            symbolName: "checklist",
            grantedText: "Reminder 접근이 준비되었습니다.",
            requestText: "Reminder 권한 요청",
            onRequest: onRequest
        )
    }
}

private struct BlockSetupStepView: View {
    let hasCalendar: Bool
    let hasReminderList: Bool
    let isWorking: Bool
    let onSetup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatusLine(title: "BLOCK Calendar", isDone: hasCalendar)
            StatusLine(title: "BLOCK Reminder List", isDone: hasReminderList)
            Button(action: onSetup) {
                if isWorking { ProgressView() }
                else { Label("BLOCK 생성 / 확인", systemImage: "square.grid.2x2") }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct FirstAreaStepView: View {
    @Binding var title: String
    let areas: [ProjectArea]
    @Binding var selectedAreaId: UUID?
    let isWorking: Bool
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Area 이름", text: $title)
                .textFieldStyle(.roundedBorder)
            Button(action: onCreate) {
                if isWorking { ProgressView() }
                else { Label("Area 만들기", systemImage: "plus.circle") }
            }
            .buttonStyle(.borderedProminent)
            if !areas.isEmpty {
                Picker("현재 Area", selection: $selectedAreaId) {
                    ForEach(areas) { area in Text(area.title).tag(area.id as UUID?) }
                }
            }
        }
    }
}

private struct FirstProjectStepView: View {
    @Binding var title: String
    @Binding var selectedAreaId: UUID?
    let areas: [ProjectArea]
    let projects: [Project]
    let isWorking: Bool
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Project 이름", text: $title)
                .textFieldStyle(.roundedBorder)
            Picker("Area", selection: $selectedAreaId) {
                Text("Area 없음").tag(nil as UUID?)
                ForEach(areas) { area in Text(area.title).tag(area.id as UUID?) }
            }
            Button(action: onCreate) {
                if isWorking { ProgressView() }
                else { Label("Project 만들기", systemImage: "folder.badge.plus") }
            }
            .buttonStyle(.borderedProminent)
            Text("Project는 Area 안의 운영 단위입니다. 새 Calendar / Reminder List를 만들지 않고 Area sync를 사용합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FirstRawTaskStepView: View {
    @Binding var title: String
    @Binding var selectedProjectId: UUID?
    let projects: [Project]
    let isWorking: Bool
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("RawTask 제목", text: $title)
                .textFieldStyle(.roundedBorder)
            Picker("Project", selection: $selectedProjectId) {
                Text("Project 없음").tag(nil as UUID?)
                ForEach(projects.filter { $0.status != .archived }) { project in
                    Text(project.title).tag(project.id as UUID?)
                }
            }
            Button(action: onCreate) {
                if isWorking { ProgressView() }
                else { Label("RawTask 만들기", systemImage: "tray.and.arrow.down") }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct FirstWorkBlockStepView: View {
    let projects: [Project]
    let rawTasks: [RawTask]
    let isWorking: Bool
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RawTask를 Plan의 HourGrid 위에 올리면 WorkBlock이 됩니다.")
                .font(.subheadline)
            Text("이번 설정에서는 09:00~09:40 예시 블록을 만듭니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(action: onCreate) {
                if isWorking { ProgressView() }
                else { Label("첫 WorkBlock 배치", systemImage: "clock.badge.checkmark") }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct PermissionStepBody: View {
    let isGranted: Bool
    let symbolName: String
    let grantedText: String
    let requestText: String
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(isGranted ? grantedText : "권한이 필요합니다.", systemImage: symbolName)
                .font(.headline)
            Button(requestText, action: onRequest)
                .buttonStyle(.borderedProminent)
                .disabled(isGranted)
        }
    }
}

private struct StatusLine: View {
    let title: String
    let isDone: Bool

    var body: some View {
        HStack {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isDone ? .green : .secondary)
            Text(title)
            Spacer()
            StatusBadge(isDone ? "Ready" : "Needed", tone: isDone ? .green : .orange)
        }
    }
}

private struct ConceptRow: View {
    let term: String
    let description: String

    var body: some View {
        HStack {
            Text(term)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
