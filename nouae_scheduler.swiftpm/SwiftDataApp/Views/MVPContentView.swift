import SwiftData
import SwiftUI

struct MVPContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "rectangle.grid.2x2") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "folder") }
            PlanView()
                .tabItem { Label("Plan", systemImage: "clock") }
            LogView()
                .tabItem { Label("Log", systemImage: "square.and.pencil") }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]

    private var todayBlocks: [WorkBlock] { blocks.filter { Calendar.current.isDateInToday($0.startAt) } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("오늘은 \(todayBlocks.count)개의 작업 블록이 있습니다. 시간의 흐름을 확인하고 한 블록씩 시작하세요.")
                        .font(.headline)
                }
                Section("오늘 상태") {
                    HStack {
                        metric("예정", count: todayBlocks.filter { $0.executionState == .planned }.count)
                        metric("진행중", count: todayBlocks.filter { $0.executionState == .inProgress }.count)
                        metric("완료", count: todayBlocks.filter { $0.executionState == .completed }.count)
                    }
                }
                Section("Active Projects") {
                    ForEach(projects.filter { !$0.isArchived && $0.status != .completed }.prefix(4)) { project in
                        NavigationLink(value: project.id) { ProjectRow(project: project) }
                    }
                }
                Section("오늘 주요 WorkBlock") {
                    ForEach(todayBlocks.prefix(5)) { block in WorkBlockRow(block: block) }
                }
                Section("최근 다음 조정") {
                    ForEach(adjustments.filter(\.isActive).prefix(3)) { adjustment in
                        Text(adjustment.content)
                    }
                }
            }
            .navigationTitle("nou ae")
            .navigationDestination(for: UUID.self) { id in
                if let project = projects.first(where: { $0.id == id }) {
                    ProjectDashboardView(project: project)
                }
            }
        }
    }

    private func metric(_ title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)").font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CalendarView: View {
    enum ViewType: String, CaseIterable, Identifiable { case day = "Day", week = "Week", month = "Month"; var id: String { rawValue } }
    @EnvironmentObject private var services: AppServices
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @State private var viewType: ViewType = .day
    @State private var selectedDate = Date()
    @State private var events: [CalendarEventSnapshot] = []
    @State private var selectedCalendarIds: Set<String> = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("보기", selection: $viewType) {
                        ForEach(ViewType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    DatePicker("기준 날짜", selection: $selectedDate, displayedComponents: .date)
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
                Section("Apple Calendar Events") {
                    if events.isEmpty { Text("선택한 기간에 일정이 없습니다.").foregroundStyle(.secondary) }
                    ForEach(events) { event in
                        HStack(alignment: .top) {
                            Circle().fill(Color(calendarHex: event.colorHex)).frame(width: 10, height: 10).padding(.top, 5)
                            VStack(alignment: .leading) {
                                Text(event.title)
                                Text(event.startAt.formatted(date: .abbreviated, time: .shortened) + " - " + event.endAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(event.calendarTitle).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                Menu {
                    Button("전체 선택") { selectedCalendarIds = Set(projects.compactMap(\.calendarIdentifier)); reload() }
                    Button("전체 해제") { selectedCalendarIds = []; events = [] }
                    Divider()
                    ForEach(projects.filter { $0.calendarIdentifier != nil }) { project in
                        Toggle(project.title, isOn: selectionBinding(for: project))
                    }
                } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
            }
            .task { selectedCalendarIds = Set(projects.compactMap(\.calendarIdentifier)); await loadEvents() }
            .onChange(of: selectedDate) { reload() }
            .onChange(of: viewType) { reload() }
        }
    }

    private func selectionBinding(for project: Project) -> Binding<Bool> {
        Binding(get: { project.calendarIdentifier.map(selectedCalendarIds.contains) ?? false }, set: { isOn in
            guard let id = project.calendarIdentifier else { return }
            if isOn { selectedCalendarIds.insert(id) } else { selectedCalendarIds.remove(id) }
            reload()
        })
    }

    private func reload() { Task { await loadEvents() } }

    private func loadEvents() async {
        let calendar = Calendar.current
        let start: Date
        let end: Date
        switch viewType {
        case .day:
            start = calendar.startOfDay(for: selectedDate); end = calendar.date(byAdding: .day, value: 1, to: start)!
        case .week:
            start = calendar.dateInterval(of: .weekOfYear, for: selectedDate)!.start; end = calendar.date(byAdding: .day, value: 7, to: start)!
        case .month:
            start = calendar.dateInterval(of: .month, for: selectedDate)!.start; end = calendar.date(byAdding: .month, value: 1, to: start)!
        }
        do { events = try await services.calendarSyncManager.fetchEvents(from: start, to: end, calendarIds: selectedCalendarIds); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
}

struct ProjectsView: View {
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @State private var showingAddProject = false

    var body: some View {
        NavigationStack {
            List(projects.filter { !$0.isArchived }) { project in
                NavigationLink { ProjectDashboardView(project: project) } label: { ProjectRow(project: project) }
            }
            .navigationTitle("Projects")
            .toolbar { Button { showingAddProject = true } label: { Image(systemName: "plus") } }
            .sheet(isPresented: $showingAddProject) { AddProjectView() }
        }
    }
}

struct ProjectRow: View {
    let project: Project
    var body: some View {
        HStack {
            Circle().fill(Color(calendarHex: project.calendarColorHex)).frame(width: 12, height: 12)
            VStack(alignment: .leading) {
                Text(project.title).font(.headline)
                Text(project.type.title + " · " + project.status.title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: project.calendarIdentifier == nil ? "calendar.badge.exclamationmark" : "calendar.badge.checkmark")
                .foregroundStyle(.secondary)
        }
    }
}

struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @State private var title = ""
    @State private var goal = ""
    @State private var type: ProjectType = .personal
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("프로젝트명", text: $title)
                Picker("성격", selection: $type) { ForEach(ProjectType.allCases) { Text($0.title).tag($0) } }
                TextField("목표", text: $goal, axis: .vertical)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("새 프로젝트")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("생성") { create() }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }

    private func create() {
        Task {
            do {
                let project = try stores.projectStore.createProject(title: title, type: type, goal: goal)
                try await services.calendarSyncManager.createCalendarForProject(project)
                dismiss()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}

struct ProjectDashboardView: View {
    let project: Project
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \WorkBlock.startAt, order: .reverse) private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query(sort: \ProjectMemoSection.order) private var sections: [ProjectMemoSection]

    var body: some View {
        List {
            Section("Project Summary") { ProjectRow(project: project); Text(project.goal.isEmpty ? "목표를 입력하세요." : project.goal) }
            Section("Inbox") { ForEach(tasks.filter { $0.projectId == project.id && !$0.isConvertedToBlock }) { Text($0.title) } }
            Section("오늘 작업") { ForEach(blocks.filter { $0.projectId == project.id && Calendar.current.isDateInToday($0.startAt) }) { WorkBlockRow(block: $0) } }
            Section("메모") { ForEach(sections.filter { $0.projectId == project.id }) { section in VStack(alignment: .leading) { Text(section.title).font(.headline); Text(section.content.isEmpty ? "내용 없음" : section.content).foregroundStyle(.secondary) } } }
            Section("최근 로그") { ForEach(logs.filter { $0.projectId == project.id }.prefix(3)) { Text($0.content.isEmpty ? "회고 메모 없음" : $0.content) } }
        }
        .navigationTitle(project.title)
    }
}

struct PlanView: View {
    enum LayoutMode: String, CaseIterable, Identifiable { case horizontal = "좌우", vertical = "상하"; var id: String { rawValue } }
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @State private var title = ""
    @State private var layoutMode: LayoutMode = .horizontal

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                Group {
                    if layoutMode == .horizontal && proxy.size.width > 700 {
                        HStack(spacing: 0) { inbox.frame(width: proxy.size.width * 0.36); Divider(); board }
                    } else {
                        VStack(spacing: 0) { inbox.frame(height: proxy.size.height * 0.42); Divider(); board }
                    }
                }
            }
            .navigationTitle("Plan")
            .toolbar { Picker("레이아웃", selection: $layoutMode) { ForEach(LayoutMode.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).frame(width: 120) }
        }
    }

    private var inbox: some View {
        List {
            Section("Quick Capture") {
                HStack { TextField("할 일 제목", text: $title); Button { addTask() } label: { Image(systemName: "plus.circle.fill") }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            Section("RawTask Inbox") {
                ForEach(tasks.filter { !$0.isConvertedToBlock }) { task in
                    Button { place(task) } label: { Label(task.title, systemImage: "arrow.right.circle") }
                }
            }
        }
    }

    private var board: some View {
        List {
            Section("Calendar Board · Today") {
                ForEach(blocks.filter { Calendar.current.isDateInToday($0.startAt) }) { block in
                    WorkBlockRow(block: block)
                        .swipeActions(edge: .trailing) {
                            Button("완료") { setState(block, .completed) }.tint(.green)
                            Button("미룸") { setState(block, .delayed) }.tint(.orange)
                        }
                        .swipeActions(edge: .leading) { Button("시작") { setState(block, .inProgress) }.tint(.blue) }
                }
            }
        }
    }

    private func addTask() { let value = title; title = ""; if let task = try? stores.rawTaskStore.createRawTask(title: value) { Task { await services.reminderSyncManager.exportRawTask(task) } } }
    private func place(_ task: RawTask) {
        let start = DateSnapper.snapToTenMinutes(Date())
        let end = Calendar.current.date(byAdding: .hour, value: 1, to: start)!
        let project = task.projectId.flatMap { id in projects.first { $0.id == id } }
        if let block = try? stores.rawTaskStore.convertToWorkBlock(task, startAt: start, endAt: end, calendarIdentifier: project?.calendarIdentifier) { services.calendarSyncManager.scheduleWorkBlockSync(block) }
    }
    private func setState(_ block: WorkBlock, _ state: WorkBlockState) { try? stores.workBlockStore.updateState(block, state: state); services.calendarSyncManager.scheduleWorkBlockSync(block) }
}

struct WorkBlockRow: View {
    let block: WorkBlock
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.title).font(.headline)
            Text(block.startAt.formatted(date: .omitted, time: .shortened) + " - " + block.endAt.formatted(date: .omitted, time: .shortened))
                .font(.caption).foregroundStyle(.secondary)
            Text(block.executionState.title + " · " + block.syncState.title).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct LogView: View {
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @State private var projectId: UUID?
    @State private var focusLevel = 3
    @State private var blockerNote = ""
    @State private var adjustment = ""
    @State private var content = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("오늘 회고") {
                    Picker("프로젝트", selection: $projectId) { Text("미연결").tag(UUID?.none); ForEach(projects.filter { !$0.isArchived }) { Text($0.title).tag(UUID?.some($0.id)) } }
                    Stepper("집중도 \(focusLevel)", value: $focusLevel, in: 1...5)
                    TextField("막힌 원인", text: $blockerNote, axis: .vertical)
                    TextField("다음 조정", text: $adjustment, axis: .vertical)
                    TextField("자유 회고", text: $content, axis: .vertical)
                    Button("로그 저장") { save() }
                }
                Section("최근 로그") { ForEach(logs.prefix(10)) { Text($0.content.isEmpty ? "회고 메모 없음" : $0.content) } }
            }
            .navigationTitle("Log")
        }
    }

    private func save() {
        try? stores.logStore.createLog(projectId: projectId, focusLevel: focusLevel, blockerNote: blockerNote, nextAdjustment: adjustment, content: content)
        blockerNote = ""; adjustment = ""; content = ""
    }
}
