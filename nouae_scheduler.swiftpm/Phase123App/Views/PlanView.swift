import SwiftData
import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]

    @State private var captureTitle = ""
    @State private var boardDate = Date()
    @State private var selectedProjectId: UUID?
    @State private var placementTask: RawTask?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width >= 760 {
                    HStack(spacing: 0) {
                        inboxPanel
                            .frame(width: min(360, geometry.size.width * 0.38))
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
            .task {
                if services.eventKit.hasReminderFullAccess { await importReminders() }
                if services.eventKit.hasFullAccess { try? await services.calendarSync.refreshLinkedEvents() }
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
            List(inboxTasks) { task in
                RawTaskRow(task: task) { placementTask = task }
            }
            .listStyle(.plain)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }

    private var boardPanel: some View {
        VStack(spacing: 0) {
            HStack {
                DatePicker("날짜", selection: $boardDate, displayedComponents: .date)
                    .labelsHidden()
                Spacer()
                Label("Day", systemImage: "calendar.day.timeline.left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            CalendarBoard(
                date: boardDate,
                blocks: dayBlocks,
                projects: projects,
                onDropTask: drop,
                onChangeTime: updateTime
            )
        }
    }

    private var inboxTasks: [RawTask] { tasks.filter { !$0.isConvertedToBlock } }
    private var activeProjects: [Project] { projects.filter { $0.status != .archived } }
    private var dayBlocks: [WorkBlock] { blocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: boardDate) } }

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
            if block.calendarIdentifier != nil { services.calendarSync.scheduleSync(block: block) }
            Task { try? await services.reminderSync.markReminderCompleted(for: task) }
        } catch {
            message = error.localizedDescription
        }
    }

    private func updateTime(block: WorkBlock, startAt: Date, endAt: Date) {
        do {
            try stores.workBlockStore.updateTime(block: block, startAt: startAt, endAt: endAt)
            if block.calendarIdentifier != nil { services.calendarSync.scheduleSync(block: block) }
        } catch {
            message = error.localizedDescription
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
