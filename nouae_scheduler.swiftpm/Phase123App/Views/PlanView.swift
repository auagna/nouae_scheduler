import Foundation
import SwiftData
import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]
    @Query(sort: \Routine.updatedAt, order: .reverse) private var routines: [Routine]

    @AppStorage("nouae.sharedSelectedDate") private var sharedSelectedDateTime: Double = Date().timeIntervalSinceReferenceDate
    @State private var captureTitle = ""
    @State private var boardDate = Date()
    @State private var planViewType: PlanViewType = .day
    @State private var selectedProjectId: UUID?
    @State private var placementTask: RawTask?
    @State private var completedLogBlock: WorkBlock?
    @State private var unplanCandidate: WorkBlock?
    @State private var showingAddRoutine = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width >= 760 {
                    HStack(spacing: 0) {
                        inboxPanel
                            .frame(width: min(360, geometry.size.width * 0.36))
                        Divider()
                        boardPanel
                    }
                } else {
                    VStack(spacing: 0) {
                        inboxPanel
                            .frame(height: min(330, geometry.size.height * 0.42))
                        Divider()
                        boardPanel
                    }
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await importReminders() } } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .accessibilityLabel("Apple Reminders 가져오기")
                }
            }
            .sheet(item: $placementTask) { task in
                PlaceRawTaskSheet(task: task, projects: activeProjects, initialDate: boardDate) { projectId, startAt, endAt in
                    place(task: task, projectId: projectId, startAt: startAt, endAt: endAt)
                }
            }
            .sheet(item: $completedLogBlock) { block in
                LogEditorSheet(initialProjectId: block.projectId, initialWorkBlockId: block.id)
            }
            .sheet(isPresented: $showingAddRoutine) {
                AddRoutineSheet(projects: activeProjects, initialDate: boardDate) { title, projectId, startAt, durationMinutes, weekdayMask, notes in
                    createRoutine(
                        title: title,
                        projectId: projectId,
                        startAt: startAt,
                        durationMinutes: durationMinutes,
                        weekdayMask: weekdayMask,
                        notes: notes
                    )
                }
            }
            .confirmationDialog("WorkBlock 배치를 취소할까요?", isPresented: unplanConfirmationBinding, titleVisibility: .visible) {
                Button("Task Inbox로 되돌리기", role: .destructive) {
                    if let block = unplanCandidate {
                        Task { await unplan(block: block) }
                    }
                }
                Button("취소", role: .cancel) {
                    unplanCandidate = nil
                }
            } message: {
                Text("원본 RawTask가 있으면 다시 Inbox에 표시됩니다. Calendar Event는 삭제를 시도합니다.")
            }
            .task {
                syncBoardDateFromShared()
                if services.eventKit.hasReminderFullAccess { await importReminders() }
                if services.eventKit.hasFullAccess { try? await services.calendarSync.refreshLinkedEvents() }
            }
            .onChange(of: boardDate) { _, newValue in
                sharedSelectedDateTime = Calendar.current.startOfDay(for: newValue).timeIntervalSinceReferenceDate
            }
            .onChange(of: sharedSelectedDateTime) { _, _ in
                syncBoardDateFromShared()
            }
        }
    }

    private var inboxPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Capture")
                .font(.headline)
            HStack {
                TextField("할 일 입력", text: $captureTitle)
                    .textFieldStyle(.roundedBorder)
                Button { capture() } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(captureTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Picker("배치 프로젝트", selection: $selectedProjectId) {
                Text("프로젝트 없음").tag(nil as UUID?)
                ForEach(activeProjects) { project in
                    Text(project.title).tag(project.id as UUID?)
                }
            }
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            RoutineTemplatesPanel(
                routines: todaysRoutines,
                projects: projects,
                selectedDate: boardDate,
                onAddRoutine: { showingAddRoutine = true },
                onGenerate: materializeRoutine
            )

            List(inboxTasks) { task in
                RawTaskRow(task: task) { placementTask = task }
                    .draggable(task.id.uuidString)
            }
            .listStyle(.plain)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }

    private var boardPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                DatePicker("날짜", selection: $boardDate, displayedComponents: .date)
                    .labelsHidden()
                PlanViewTypePicker(selection: $planViewType)
                    .frame(maxWidth: 320)
                Spacer()
                #if DEBUG
                Text("HourGridPlanBoard ACTIVE")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red, in: Capsule())
                #endif
            }
            .padding()

            switch planViewType {
            case .day:
                WorkBlockExecutionPanel(blocks: dayBlocks, projects: projects, onAction: perform)

                HourGridPlanBoard(
                    date: boardDate,
                    blocks: dayBlocks,
                    projects: projects,
                    onDropTask: drop,
                    onChangeTime: updateTime,
                    onUnplan: { block in unplanCandidate = block },
                    onAction: perform
                )
            case .week:
                ScrollView {
                    PlanWeekView(selectedDate: boardDate, blocks: blocks) { date in
                        boardDate = date
                        planViewType = .day
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
            case .month:
                ScrollView {
                    PlanMonthView(selectedDate: boardDate, blocks: blocks) { date in
                        boardDate = date
                        planViewType = .day
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
    }

    private var inboxTasks: [RawTask] { tasks.filter { stores.rawTaskStore.isVisibleInInbox($0) } }
    private var activeProjects: [Project] { projects.filter { $0.status != .archived } }
    private var dayBlocks: [WorkBlock] { blocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: boardDate) } }
    private var todaysRoutines: [Routine] {
        routines
            .filter { $0.occurs(on: boardDate) }
            .sorted { $0.startMinuteOfDay < $1.startMinuteOfDay }
    }
    private var unplanConfirmationBinding: Binding<Bool> {
        Binding(
            get: { unplanCandidate != nil },
            set: { if !$0 { unplanCandidate = nil } }
        )
    }

    private func createRoutine(title: String, projectId: UUID?, startAt: Date, durationMinutes: Int, weekdayMask: Int, notes: String) {
        let project = projects.first { $0.id == projectId }
        let components = Calendar.current.dateComponents([.hour, .minute], from: startAt)
        let startMinute = (components.hour ?? 9) * 60 + (components.minute ?? 0)
        let frequency: RoutineFrequency
        if weekdayMask == RoutineWeekday.everyDayMask {
            frequency = .daily
        } else if weekdayMask == RoutineWeekday.weekdaysMask {
            frequency = .weekdays
        } else {
            frequency = .custom
        }

        do {
            _ = try stores.routineStore.createRoutine(
                title: title,
                areaId: project?.areaId,
                projectId: projectId,
                frequency: frequency,
                weekdayMask: weekdayMask,
                startMinuteOfDay: startMinute,
                durationMinutes: durationMinutes,
                notes: notes
            )
            message = "Routine template을 만들었습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func materializeRoutine(_ routine: Routine) {
        do {
            let result = try stores.routineStore.materializeRoutine(routine, on: boardDate)
            services.calendarSync.scheduleSync(block: result.block)
            message = "Routine Occurrence를 WorkBlock으로 배치했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func capture() {
        let value = captureTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        captureTitle = ""
        do {
            let task = try stores.rawTaskStore.createRawTask(title: value)
            Task { try? await services.reminderSync.exportRawTask(task) }
        } catch {
            message = error.localizedDescription
        }
    }

    private func importReminders() async {
        do {
            let count = try await services.reminderSync.importInboxReminders()
            message = "Apple Reminders \(count)개를 확인했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func drop(taskId: UUID, startAt: Date) {
        guard let task = tasks.first(where: { $0.id == taskId }) else { return }
        let endAt = Calendar.current.date(byAdding: .minute, value: 60, to: startAt) ?? startAt
        place(task: task, projectId: task.projectId ?? selectedProjectId, startAt: startAt, endAt: endAt)
    }

    private func place(task: RawTask, projectId: UUID?, startAt: Date, endAt: Date) {
        let project = projects.first { $0.id == projectId }
        do {
            let block = try stores.workBlockStore.convert(task: task, project: project, startAt: startAt, endAt: endAt)
            services.calendarSync.scheduleSync(block: block)
            Task { try? await services.reminderSync.markReminderCompleted(for: task) }
        } catch {
            message = error.localizedDescription
        }
    }

    private func updateTime(block: WorkBlock, startAt: Date, endAt: Date) {
        do {
            try stores.workBlockStore.updateTime(block: block, startAt: startAt, endAt: endAt)
            services.calendarSync.scheduleSync(block: block)
        } catch {
            message = error.localizedDescription
        }
    }

    private func perform(block: WorkBlock, action: WorkBlockAction) {
        do {
            switch action {
            case .start:
                try stores.workBlockStore.start(block: block)
            case .complete:
                try stores.workBlockStore.markCompleted(block: block)
                completedLogBlock = block
            case .delay:
                let task = try stores.workBlockStore.markDelayed(block: block)
                Task { try? await services.reminderSync.exportRawTask(task) }
            case .stop:
                try stores.workBlockStore.markStopped(block: block)
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func unplan(block: WorkBlock) async {
        let eventIdentifier = block.eventIdentifier
        do {
            if let eventIdentifier {
                try? await services.calendarSync.deleteEvent(identifier: eventIdentifier)
            }
            let task = try stores.workBlockStore.unplan(block: block)
            Task { try? await services.reminderSync.exportRawTask(task) }
            message = "WorkBlock을 Task Inbox로 되돌렸습니다."
        } catch {
            message = error.localizedDescription
        }
        unplanCandidate = nil
    }

    private func syncBoardDateFromShared() {
        let sharedDate = Date(timeIntervalSinceReferenceDate: sharedSelectedDateTime)
        if !Calendar.current.isDate(sharedDate, inSameDayAs: boardDate) {
            boardDate = sharedDate
        }
    }
}

private struct RoutineTemplatesPanel: View {
    let routines: [Routine]
    let projects: [Project]
    let selectedDate: Date
    let onAddRoutine: () -> Void
    let onGenerate: (Routine) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Routine Templates")
                        .font(.headline)
                    Text("반복 가능한 생활·작업 시간을 오늘의 WorkBlock으로 만듭니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    onAddRoutine()
                } label: {
                    Image(systemName: "plus.circle")
                }
                .accessibilityLabel("Routine 추가")
            }

            if routines.isEmpty {
                Text("선택한 날짜에 해당하는 Routine이 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(routines.prefix(4)) { routine in
                        RoutineTemplateRow(
                            routine: routine,
                            project: projects.first { $0.id == routine.projectId },
                            selectedDate: selectedDate,
                            onGenerate: { onGenerate(routine) }
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct RoutineTemplateRow: View {
    let routine: Routine
    let project: Project?
    let selectedDate: Date
    let onGenerate: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(Color(calendarHex: project?.calendarColorHex))
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 3) {
                Text(routine.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button("오늘 배치") {
                onGenerate()
            }
            .buttonStyle(.bordered)
            .font(.caption.weight(.semibold))
        }
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var subtitle: String {
        let start = Calendar.current.date(
            byAdding: .minute,
            value: routine.startMinuteOfDay,
            to: Calendar.current.startOfDay(for: selectedDate)
        ) ?? selectedDate
        let end = Calendar.current.date(byAdding: .minute, value: routine.durationMinutes, to: start) ?? start
        let projectTitle = project?.title ?? "BLOCK"
        return "\(projectTitle) · \(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))"
    }
}

private struct AddRoutineSheet: View {
    let projects: [Project]
    let onSave: (String, UUID?, Date, Int, Int, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var projectId: UUID?
    @State private var startAt: Date
    @State private var durationMinutes = 60
    @State private var selectedWeekdays = Set(RoutineWeekday.allCases.map { $0.rawValue })
    @State private var notes = ""

    init(
        projects: [Project],
        initialDate: Date,
        onSave: @escaping (String, UUID?, Date, Int, Int, String) -> Void
    ) {
        self.projects = projects
        self.onSave = onSave
        let start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: initialDate) ?? initialDate
        _startAt = State(initialValue: start)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine") {
                    TextField("루틴 이름", text: $title)
                    Picker("Project", selection: $projectId) {
                        Text("프로젝트 없음 · BLOCK").tag(nil as UUID?)
                        ForEach(projects) { project in
                            Text(project.title).tag(project.id as UUID?)
                        }
                    }
                }

                Section("Time Template") {
                    DatePicker("시작 시간", selection: $startAt, displayedComponents: .hourAndMinute)
                    Stepper("길이 \(durationMinutes)분", value: $durationMinutes, in: 10...240, step: 10)
                }

                Section("Repeat") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(RoutineWeekday.allCases) { weekday in
                            Button {
                                toggleWeekday(weekday)
                            } label: {
                                Text(weekday.shortTitle)
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedWeekdays.contains(weekday.rawValue) ? Color.accentColor.opacity(0.18) : Color(uiColor: .secondarySystemGroupedBackground),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Notes") {
                    TextField("메모", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("New Routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(title, projectId, startAt, durationMinutes, weekdayMask, notes)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedWeekdays.isEmpty)
                }
            }
        }
    }

    private var weekdayMask: Int {
        RoutineWeekday.allCases.reduce(0) { value, weekday in
            selectedWeekdays.contains(weekday.rawValue) ? value | weekday.maskValue : value
        }
    }

    private func toggleWeekday(_ weekday: RoutineWeekday) {
        if selectedWeekdays.contains(weekday.rawValue) {
            selectedWeekdays.remove(weekday.rawValue)
        } else {
            selectedWeekdays.insert(weekday.rawValue)
        }
    }
}

struct PlaceRawTaskSheet: View {
    let task: RawTask
    let projects: [Project]
    let onPlace: (UUID?, Date, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var projectId: UUID?
    @State private var startAt: Date
    @State private var durationMinutes = 60

    init(task: RawTask, projects: [Project], initialDate: Date, onPlace: @escaping (UUID?, Date, Date) -> Void) {
        self.task = task
        self.projects = projects
        self.onPlace = onPlace
        _projectId = State(initialValue: task.projectId)
        let minute = Calendar.current.isDateInToday(initialDate) ? DateSnapper.minuteOfDay(for: Date()) : 9 * 60
        _startAt = State(initialValue: DateSnapper.date(on: initialDate, minuteOfDay: minute))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("RawTask") { Text(task.title) }
                Picker("프로젝트", selection: $projectId) {
                    Text("프로젝트 없음").tag(nil as UUID?)
                    ForEach(projects) { project in Text(project.title).tag(project.id as UUID?) }
                }
                DatePicker("시작", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                Stepper("길이 \(durationMinutes)분", value: $durationMinutes, in: 10...240, step: 10)
            }
            .navigationTitle("시간 배치")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("배치") {
                        let endAt = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startAt) ?? startAt
                        onPlace(projectId, startAt, endAt)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct HourGridPlanBoard: View {
    let date: Date
    let blocks: [WorkBlock]
    let projects: [Project]
    let onDropTask: (UUID, Date) -> Void
    let onChangeTime: (WorkBlock, Date, Date) -> Void
    let onUnplan: (WorkBlock) -> Void
    let onAction: (WorkBlock, WorkBlockAction) -> Void

    @State private var previewRanges: [UUID: HourGridRange] = [:]

    private let metrics = HourGridMetrics()
    private let visibleStartHour = 6
    private let visibleEndHour = 23

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: metrics.rowSpacing) {
                TenMinuteRuler(metrics: metrics)
                ForEach(visibleStartHour...visibleEndHour, id: \.self) { hour in
                    HourRowView(
                        hour: hour,
                        date: date,
                        metrics: metrics,
                        blocks: segments(forHour: hour),
                        projects: projects,
                        onDropTask: onDropTask,
                        onPreview: { block, range in previewRanges[block.id] = range },
                        onCommit: { block, range in
                            previewRanges[block.id] = nil
                            onChangeTime(block, range.startAt, range.endAt)
                        },
                        onCancel: { block in previewRanges[block.id] = nil },
                        onUnplan: onUnplan,
                        onAction: onAction
                    )
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func segments(forHour hour: Int) -> [HourGridSegment] {
        blocks.flatMap { block -> [HourGridSegment] in
            let range = previewRanges[block.id] ?? HourGridRange(startAt: block.startAt, endAt: block.endAt)
            return HourGridSegment.make(block: block, range: range, hour: hour, metrics: metrics)
        }
    }
}

private struct HourGridMetrics {
    let timeLabelWidth: CGFloat = 56
    let columnWidth: CGFloat = 72
    let rowHeight: CGFloat = 78
    let rowSpacing: CGFloat = 8
    let headerHeight: CGFloat = 32
    var blockHeight: CGFloat { rowHeight }
    let blockVerticalInset: CGFloat = 0
    let snapMinutes = 10

    var gridWidth: CGFloat { columnWidth * 6 }
    var minuteWidth: CGFloat { columnWidth / CGFloat(snapMinutes) }

    func xForColumn(_ column: Int) -> CGFloat { CGFloat(column) * columnWidth }
    func minuteColumn(for minute: Int) -> Int { min(max(minute / snapMinutes, 0), 6) }
    func snapColumn(from translation: CGFloat) -> Int { Int((translation / columnWidth).rounded()) }
    func snapHourDelta(from translation: CGFloat) -> Int { Int((translation / (rowHeight + rowSpacing)).rounded()) }
    func snappedMinuteDelta(translation: CGFloat) -> Int { snapColumn(from: translation) * snapMinutes }
}

private struct HourGridRange {
    var startAt: Date
    var endAt: Date

    func moved(minuteDelta: Int, hourDelta: Int) -> HourGridRange {
        let delta = minuteDelta + hourDelta * 60
        return HourGridRange(
            startAt: Calendar.current.date(byAdding: .minute, value: delta, to: startAt) ?? startAt,
            endAt: Calendar.current.date(byAdding: .minute, value: delta, to: endAt) ?? endAt
        )
    }

    func resizedStart(minuteDelta: Int) -> HourGridRange {
        let proposed = Calendar.current.date(byAdding: .minute, value: minuteDelta, to: startAt) ?? startAt
        let maxStart = Calendar.current.date(byAdding: .minute, value: -DateSnapper.minimumDurationMinutes, to: endAt) ?? startAt
        return HourGridRange(startAt: min(proposed, maxStart), endAt: endAt)
    }

    func resizedEnd(minuteDelta: Int) -> HourGridRange {
        let proposed = Calendar.current.date(byAdding: .minute, value: minuteDelta, to: endAt) ?? endAt
        let minEnd = Calendar.current.date(byAdding: .minute, value: DateSnapper.minimumDurationMinutes, to: startAt) ?? endAt
        return HourGridRange(startAt: startAt, endAt: max(proposed, minEnd))
    }
}

private struct HourGridSegment: Identifiable {
    let id = UUID()
    let block: WorkBlock
    let range: HourGridRange
    let startColumn: Int
    let endColumn: Int

    var widthColumns: Int { max(1, endColumn - startColumn) }

    static func make(block: WorkBlock, range: HourGridRange, hour: Int, metrics: HourGridMetrics) -> [HourGridSegment] {
        let calendar = Calendar.current
        let start = calendar.dateComponents([.hour, .minute], from: range.startAt)
        let end = calendar.dateComponents([.hour, .minute], from: range.endAt)
        let startHour = start.hour ?? 0
        let endHour = end.hour ?? 0
        let startMinute = start.minute ?? 0
        let endMinute = end.minute ?? 0

        let effectiveEndHour = endMinute == 0 ? endHour - 1 : endHour
        guard hour >= startHour && hour <= effectiveEndHour else { return [] }
        if startHour == endHour {
            let left = metrics.minuteColumn(for: startMinute)
            let right = max(left + 1, metrics.minuteColumn(for: endMinute))
            return [HourGridSegment(block: block, range: range, startColumn: left, endColumn: right)]
        }
        if hour == startHour {
            return [HourGridSegment(block: block, range: range, startColumn: metrics.minuteColumn(for: startMinute), endColumn: 6)]
        }
        if hour == endHour {
            let right = max(1, metrics.minuteColumn(for: endMinute))
            return [HourGridSegment(block: block, range: range, startColumn: 0, endColumn: right)]
        }
        return [HourGridSegment(block: block, range: range, startColumn: 0, endColumn: 6)]
    }
}

private struct TenMinuteRuler: View {
    let metrics: HourGridMetrics

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: metrics.timeLabelWidth)
            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                Text(String(format: "%02d", minute))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: metrics.columnWidth, alignment: .leading)
            }
        }
        .frame(height: metrics.headerHeight)
    }
}

private struct HourRowView: View {
    let hour: Int
    let date: Date
    let metrics: HourGridMetrics
    let blocks: [HourGridSegment]
    let projects: [Project]
    let onDropTask: (UUID, Date) -> Void
    let onPreview: (WorkBlock, HourGridRange) -> Void
    let onCommit: (WorkBlock, HourGridRange) -> Void
    let onCancel: (WorkBlock) -> Void
    let onUnplan: (WorkBlock) -> Void
    let onAction: (WorkBlock, WorkBlockAction) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(String(format: "%02d:00", hour))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: metrics.timeLabelWidth, alignment: .leading)

            ZStack(alignment: .leading) {
                HourGridBackground(metrics: metrics)
                ForEach(blocks) { segment in
                    HourGridWorkBlockSegment(
                        segment: segment,
                        project: projects.first { $0.id == segment.block.projectId },
                        metrics: metrics,
                        onPreview: onPreview,
                        onCommit: onCommit,
                        onCancel: onCancel,
                        onUnplan: onUnplan,
                        onAction: onAction
                    )
                    .frame(
                        width: CGFloat(segment.widthColumns) * metrics.columnWidth,
                        height: metrics.blockHeight
                    )
                    .offset(
                        x: metrics.xForColumn(segment.startColumn),
                        y: metrics.blockVerticalInset
                    )
                }
            }
            .frame(width: metrics.gridWidth, height: metrics.rowHeight, alignment: .topLeading)
            .dropDestination(for: String.self) { items, location in
                guard let rawId = items.first, let id = UUID(uuidString: rawId) else { return false }
                let column = min(max(Int((location.x / metrics.columnWidth).rounded(.down)), 0), 5)
                let minute = hour * 60 + column * metrics.snapMinutes
                let startAt = DateSnapper.date(on: date, minuteOfDay: minute)
                onDropTask(id, startAt)
                return true
            }
        }
    }
}

private struct HourGridBackground: View {
    let metrics: HourGridMetrics

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
            ForEach(0...6, id: \.self) { column in
                Rectangle()
                    .fill(Color(uiColor: .separator).opacity(column == 0 || column == 6 ? 0.45 : 0.22))
                    .frame(width: 1)
                    .offset(x: metrics.xForColumn(column))
            }
        }
    }
}

private struct HourGridWorkBlockSegment: View {
    let segment: HourGridSegment
    let project: Project?
    let metrics: HourGridMetrics
    let onPreview: (WorkBlock, HourGridRange) -> Void
    let onCommit: (WorkBlock, HourGridRange) -> Void
    let onCancel: (WorkBlock) -> Void
    let onUnplan: (WorkBlock) -> Void
    let onAction: (WorkBlock, WorkBlockAction) -> Void
    @State private var activeDragMode: ActiveDragMode = .none

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(projectColor.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(projectColor, lineWidth: 1)
                )
            HStack(spacing: 6) {
                grip(systemImage: "line.3.horizontal")
                    .highPriorityGesture(resizeGesture(edge: .left))
                VStack(alignment: .leading, spacing: 2) {
                    Text(segment.block.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(segment.block.executionState.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Menu {
                    Button("Start") { onAction(segment.block, .start) }
                    Button("Complete") { onAction(segment.block, .complete) }
                    Button("Delay") { onAction(segment.block, .delay) }
                    Button("배치 취소", role: .destructive) { onUnplan(segment.block) }
                    Button("Stop", role: .destructive) { onAction(segment.block, .stop) }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.caption)
                }
                grip(systemImage: "line.3.horizontal")
                    .highPriorityGesture(resizeGesture(edge: .right))
            }
            .padding(.horizontal, 8)
        }
        .contentShape(Rectangle())
        .gesture(moveGesture)
    }

    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard activeDragMode == .none || activeDragMode == .body else { return }
                activeDragMode = .body
                let minuteDelta = metrics.snappedMinuteDelta(translation: value.translation.width)
                let hourDelta = metrics.snapHourDelta(from: value.translation.height)
                onPreview(segment.block, segment.range.moved(minuteDelta: minuteDelta, hourDelta: hourDelta))
            }
            .onEnded { value in
                guard activeDragMode == .body else {
                    activeDragMode = .none
                    return
                }
                let minuteDelta = metrics.snappedMinuteDelta(translation: value.translation.width)
                let hourDelta = metrics.snapHourDelta(from: value.translation.height)
                onCommit(segment.block, segment.range.moved(minuteDelta: minuteDelta, hourDelta: hourDelta))
                activeDragMode = .none
            }
    }

    private func resizeGesture(edge: ResizeEdge) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let mode: ActiveDragMode = edge == .left ? .leftResize : .rightResize
                guard activeDragMode == .none || activeDragMode == mode else { return }
                activeDragMode = mode
                let minuteDelta = metrics.snappedMinuteDelta(translation: value.translation.width)
                let range = edge == .left ? segment.range.resizedStart(minuteDelta: minuteDelta) : segment.range.resizedEnd(minuteDelta: minuteDelta)
                onPreview(segment.block, range)
            }
            .onEnded { value in
                let mode: ActiveDragMode = edge == .left ? .leftResize : .rightResize
                guard activeDragMode == mode else {
                    activeDragMode = .none
                    return
                }
                let minuteDelta = metrics.snappedMinuteDelta(translation: value.translation.width)
                let range = edge == .left ? segment.range.resizedStart(minuteDelta: minuteDelta) : segment.range.resizedEnd(minuteDelta: minuteDelta)
                onCommit(segment.block, range)
                activeDragMode = .none
            }
    }

    private func grip(systemImage: String) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(projectColor.opacity(0.72))
            .frame(width: 4, height: 30)
            .frame(width: 24, height: 44)
            .contentShape(Rectangle())
    }

    private enum ResizeEdge { case left, right }
    private enum ActiveDragMode { case none, body, leftResize, rightResize }

    private var projectColor: Color {
        guard let project else { return .blue }
        return Color(calendarHex: project.calendarColorHex)
    }
}
