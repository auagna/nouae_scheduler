import SwiftData
import SwiftUI

struct PlanView: View {
    enum LayoutMode: String, CaseIterable, Identifiable {
        case horizontal = "좌우"
        case vertical = "상하"
        var id: String { rawValue }
    }

    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @AppStorage("planLayoutMode") private var storedLayoutMode = LayoutMode.horizontal.rawValue
    @State private var title = ""
    @State private var selectedProjectId: UUID?
    @State private var selectedDate = Date()
    @State private var syncMessage: String?

    private var layoutMode: Binding<LayoutMode> {
        Binding(get: { LayoutMode(rawValue: storedLayoutMode) ?? .horizontal }, set: { storedLayoutMode = $0.rawValue })
    }
    private var inboxTasks: [RawTask] { tasks.filter { !$0.isConvertedToBlock } }
    private var dayBlocks: [WorkBlock] { blocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: selectedDate) } }
    private var selectedProject: Project? { selectedProjectId.flatMap { id in projects.first { $0.id == id } } }
    private var executionBlock: WorkBlock? {
        dayBlocks.first { $0.executionState == .inProgress } ?? dayBlocks.first { $0.executionState == .planned && $0.startAt <= Date() }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                Group {
                    if layoutMode.wrappedValue == .horizontal && proxy.size.width > 700 {
                        HStack(spacing: 0) { leftPanel.frame(width: proxy.size.width * 0.36); Divider(); rightPanel }
                    } else {
                        VStack(spacing: 0) { leftPanel.frame(height: proxy.size.height * 0.42); Divider(); rightPanel }
                    }
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { importReminders() } label: { Image(systemName: "arrow.triangle.2.circlepath") } }
                ToolbarItem(placement: .topBarTrailing) { Picker("레이아웃", selection: layoutMode) { ForEach(LayoutMode.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).frame(width: 120) }
            }
        }
    }

    private var leftPanel: some View {
        List {
            if let executionBlock {
                Section("Execution") {
                    ExecutionPanel(
                        block: executionBlock,
                        projectTitle: projectTitle(executionBlock.projectId),
                        onStart: { updateState(executionBlock, .inProgress) },
                        onComplete: { updateState(executionBlock, .completed) },
                        onDelay: { delay(executionBlock) },
                        onStop: { updateState(executionBlock, .stopped) }
                    )
                }
            }
            Section("Quick Capture") {
                HStack {
                    TextField("할 일 제목", text: $title)
                    Button { addTask() } label: { Image(systemName: "plus.circle.fill") }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            Section("배치 대상 프로젝트") {
                Picker("프로젝트", selection: $selectedProjectId) {
                    Text("미연결").tag(UUID?.none)
                    ForEach(projects.filter { !$0.isArchived }) { Text($0.title).tag(UUID?.some($0.id)) }
                }
            }
            if let syncMessage { Section { Text(syncMessage).font(.caption).foregroundStyle(.secondary) } }
            Section("RawTask Inbox") {
                ForEach(inboxTasks) { task in
                    Button { place(task, atMinute: currentMinute()) } label: {
                        HStack { Text(task.title); Spacer(); Image(systemName: "arrow.right.circle") }
                    }
                    .draggable(task.id.uuidString)
                }
            }
        }
    }

    private var rightPanel: some View {
        VStack(spacing: 0) {
            DatePicker("배치 날짜", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact).padding(.horizontal).padding(.vertical, 8)
            Divider()
            CalendarBoard(
                date: selectedDate,
                blocks: dayBlocks,
                projectColor: { projectId in projectId.flatMap { id in projects.first { $0.id == id }?.calendarColorHex } },
                onDropTask: { taskId, minute in if let task = tasks.first(where: { $0.id == taskId }) { place(task, atMinute: minute) } },
                onChangeTime: updateTime
            )
        }
    }

    private func addTask() {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        title = ""
        guard !value.isEmpty, let task = try? stores.rawTaskStore.createRawTask(title: value) else { return }
        Task { await services.reminderSyncManager.exportRawTask(task) }
    }

    private func importReminders() {
        Task {
            do { let imported = try await services.reminderSyncManager.importInboxReminders(); syncMessage = "미리알림 \(imported.count)개를 Inbox에 반영했습니다." }
            catch { syncMessage = error.localizedDescription }
        }
    }

    private func place(_ task: RawTask, atMinute minute: Int) {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let start = Calendar.current.date(byAdding: .minute, value: minute, to: startOfDay) ?? selectedDate
        let end = Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
        try? stores.rawTaskStore.assignProject(task, projectId: selectedProjectId)
        guard let block = try? stores.rawTaskStore.convertToWorkBlock(task, startAt: start, endAt: end, calendarIdentifier: selectedProject?.calendarIdentifier) else { return }
        services.calendarSyncManager.scheduleWorkBlockSync(block)
    }

    private func updateTime(_ block: WorkBlock, _ start: Date, _ end: Date) {
        try? stores.workBlockStore.updateTime(block, startAt: start, endAt: end)
        services.calendarSyncManager.scheduleWorkBlockSync(block)
    }

    private func updateState(_ block: WorkBlock, _ state: WorkBlockState) {
        try? stores.workBlockStore.updateState(block, state: state)
        services.calendarSyncManager.scheduleWorkBlockSync(block)
    }

    private func delay(_ block: WorkBlock) {
        updateState(block, .delayed)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        if let task = try? stores.rawTaskStore.createRawTask(title: block.title, projectId: block.projectId, scheduledAt: tomorrow) {
            Task { await services.reminderSyncManager.exportRawTask(task) }
        }
    }

    private func currentMinute() -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        return Int((Double(minute) / 10).rounded()) * 10
    }

    private func projectTitle(_ id: UUID?) -> String? { id.flatMap { value in projects.first { $0.id == value }?.title } }
}
