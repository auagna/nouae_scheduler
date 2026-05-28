import EventKit
import SwiftUI

@main
struct NouAESchedulerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

enum ScheduleCategory: String, CaseIterable, Identifiable, Codable {
    case work = "작업"
    case company = "회사"
    case personal = "개인"
    case social = "소셜"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .work: return .blue
        case .company: return .purple
        case .personal: return .green
        case .social: return .orange
        }
    }

    var symbol: String {
        switch self {
        case .work: return "briefcase"
        case .company: return "building.2"
        case .personal: return "person"
        case .social: return "person.2"
        }
    }

    var calendarNames: [String] {
        switch self {
        case .work: return ["작업", "Work", "work"]
        case .company: return ["회사", "Company", "company"]
        case .personal: return ["개인", "Personal", "personal"]
        case .social: return ["SOCIAL", "소셜", "Social", "social"]
        }
    }
}

struct CalendarSource: Identifiable, Equatable {
    let id: String
    let title: String
    var isSelected: Bool
}

struct CalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startAt: Date
    let endAt: Date
    let calendarTitle: String
}

struct Project: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: ScheduleCategory
    var purpose: String
    var calendarIdentifier: String?
    var createdAt = Date()
}

struct WorkBlock: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: ScheduleCategory
    var projectId: UUID?
    var projectTitle: String?
    var startAt: Date
    var endAt: Date
    var calendarIdentifier: String?
    var eventIdentifier: String?
    var syncStatus = "대기"

    var minutes: Int {
        max(0, Int(endAt.timeIntervalSince(startAt) / 60))
    }
}

@MainActor
final class EventKitManager: ObservableObject {
    @Published private(set) var calendarStatusText = "확인 필요"
    @Published private(set) var remindersStatusText = "확인 필요"

    private let eventStore = EKEventStore()

    init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        calendarStatusText = statusText(EKEventStore.authorizationStatus(for: .event))
        remindersStatusText = statusText(EKEventStore.authorizationStatus(for: .reminder))
    }

    func requestCalendarAccess() async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        refreshAuthorizationStatus()
        if !granted {
            throw AppError.message("캘린더 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.")
        }
    }

    func requestRemindersAccess() async throws {
        let granted = try await eventStore.requestFullAccessToReminders()
        refreshAuthorizationStatus()
        if !granted {
            throw AppError.message("미리알림 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.")
        }
    }

    func fetchCalendars() async throws -> [CalendarSource] {
        try ensureCalendarAccess()
        return eventStore.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { CalendarSource(id: $0.calendarIdentifier, title: $0.title, isSelected: true) }
    }

    func fetchEvents(on date: Date, calendarIds: [String]) async throws -> [CalendarEvent] {
        try ensureCalendarAccess()
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? date
        let calendars: [EKCalendar]? = calendarIds.isEmpty ? nil : calendarIds.compactMap { eventStore.calendar(withIdentifier: $0) }
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map {
                CalendarEvent(
                    id: $0.eventIdentifier ?? UUID().uuidString,
                    title: $0.title,
                    startAt: $0.startDate,
                    endAt: $0.endDate,
                    calendarTitle: $0.calendar.title
                )
            }
    }

    func saveWorkBlock(_ block: WorkBlock) async throws -> String {
        try ensureCalendarAccess()
        guard let calendarIdentifier = block.calendarIdentifier,
              let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) else {
            throw AppError.message("카테고리에 연결된 Apple Calendar가 없습니다. Calendar 탭에서 연결해 주세요.")
        }
        guard block.endAt > block.startAt else {
            throw AppError.message("종료 시간은 시작 시간보다 늦어야 합니다.")
        }

        let event: EKEvent
        if let eventIdentifier = block.eventIdentifier,
           let existing = eventStore.event(withIdentifier: eventIdentifier) {
            event = existing
        } else {
            event = EKEvent(eventStore: eventStore)
        }

        event.title = block.title.trimmingCharacters(in: .whitespacesAndNewlines)
        event.startDate = block.startAt
        event.endDate = block.endAt
        event.calendar = calendar
        event.notes = "nouae category: \(block.category.rawValue)\nprojectTitle: \(block.projectTitle ?? "")"
        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier ?? UUID().uuidString
    }

    func createReminder(title: String, dueAt: Date) async throws {
        try ensureReminderAccess()
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw AppError.message("기본 미리알림 목록을 찾을 수 없습니다.")
        }
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        reminder.calendar = calendar
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueAt)
        try eventStore.save(reminder, commit: true)
    }

    private func ensureCalendarAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .authorized || status == .fullAccess else {
            throw AppError.message("캘린더 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.")
        }
    }

    private func ensureReminderAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .authorized || status == .fullAccess else {
            throw AppError.message("미리알림 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.")
        }
    }

    private func statusText(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "아직 요청하지 않음"
        case .restricted: return "제한됨"
        case .denied: return "거부됨"
        case .authorized, .fullAccess: return "허용됨"
        case .writeOnly: return "쓰기 전용"
        @unknown default: return "알 수 없음"
        }
    }
}

@MainActor
final class CalendarSelectionStore: ObservableObject {
    @Published var calendars: [CalendarSource] = []
    @Published var categoryMap: [ScheduleCategory: String] = [:]

    private let selectedKey = "stable.selectedCalendarIds"
    private let categoryKey = "stable.categoryCalendarMap"

    init() {
        if let stored = UserDefaults.standard.dictionary(forKey: categoryKey) as? [String: String] {
            for (key, value) in stored {
                if let category = ScheduleCategory(rawValue: key) {
                    categoryMap[category] = value
                }
            }
        }
    }

    var selectedIds: [String] {
        calendars.filter(\.isSelected).map(\.id)
    }

    func setCalendars(_ sources: [CalendarSource]) {
        let saved = Set(UserDefaults.standard.stringArray(forKey: selectedKey) ?? sources.map(\.id))
        calendars = sources.map { CalendarSource(id: $0.id, title: $0.title, isSelected: saved.contains($0.id)) }
        inferCategoryMapIfNeeded()
    }

    func toggleCalendar(_ source: CalendarSource, isSelected: Bool) {
        guard let index = calendars.firstIndex(where: { $0.id == source.id }) else { return }
        calendars[index].isSelected = isSelected
        UserDefaults.standard.set(selectedIds, forKey: selectedKey)
    }

    func setCalendar(_ calendarId: String?, for category: ScheduleCategory) {
        categoryMap[category] = calendarId
        saveCategoryMap()
    }

    func calendarId(for category: ScheduleCategory) -> String? {
        categoryMap[category]
    }

    func calendarTitle(for category: ScheduleCategory) -> String {
        guard let id = categoryMap[category],
              let source = calendars.first(where: { $0.id == id }) else {
            return "연결 필요"
        }
        return source.title
    }

    private func inferCategoryMapIfNeeded() {
        for category in ScheduleCategory.allCases where categoryMap[category] == nil {
            if let source = calendars.first(where: { source in
                category.calendarNames.contains { $0.caseInsensitiveCompare(source.title) == .orderedSame }
            }) {
                categoryMap[category] = source.id
            }
        }
        saveCategoryMap()
    }

    private func saveCategoryMap() {
        let stored = Dictionary(uniqueKeysWithValues: categoryMap.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(stored, forKey: categoryKey)
    }
}

@MainActor
final class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    private let key = "stable.projects"

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Project].self, from: data) else { return }
        projects = decoded
    }

    func create(title: String, category: ScheduleCategory, purpose: String, calendarIdentifier: String?) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        projects.append(Project(title: cleanTitle, category: category, purpose: purpose, calendarIdentifier: calendarIdentifier))
        save()
    }

    func projects(for category: ScheduleCategory) -> [Project] {
        projects.filter { $0.category == category }
    }

    func project(id: UUID?) -> Project? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

@MainActor
final class TimeBlockStore: ObservableObject {
    @Published var blocks: [WorkBlock] = []
    @Published var message: String?

    private let key = "stable.blocks"
    private let eventKitManager: EventKitManager
    private let calendarSelectionStore: CalendarSelectionStore
    private var syncTasks: [UUID: Task<Void, Never>] = [:]

    init(eventKitManager: EventKitManager, calendarSelectionStore: CalendarSelectionStore) {
        self.eventKitManager = eventKitManager
        self.calendarSelectionStore = calendarSelectionStore
        load()
    }

    func create(title: String, category: ScheduleCategory, project: Project?, startAt: Date, endAt: Date) {
        let resolvedCategory = project?.category ?? category
        let block = WorkBlock(
            title: title.isEmpty ? "새 타임블록" : title,
            category: resolvedCategory,
            projectId: project?.id,
            projectTitle: project?.title,
            startAt: snap(startAt),
            endAt: max(snap(endAt), Calendar.current.date(byAdding: .minute, value: 30, to: snap(startAt)) ?? endAt),
            calendarIdentifier: project?.calendarIdentifier ?? calendarSelectionStore.calendarId(for: resolvedCategory)
        )
        blocks.append(block)
        save()
        scheduleSync(block.id)
    }

    func move(_ block: WorkBlock, minutes: Int) {
        update(block) { item in
            item.startAt = snap(Calendar.current.date(byAdding: .minute, value: minutes, to: item.startAt) ?? item.startAt)
            item.endAt = snap(Calendar.current.date(byAdding: .minute, value: minutes, to: item.endAt) ?? item.endAt)
        }
    }

    func resizeEnd(_ block: WorkBlock, minutes: Int) {
        update(block) { item in
            item.endAt = snap(Calendar.current.date(byAdding: .minute, value: minutes, to: item.endAt) ?? item.endAt)
            if item.endAt <= item.startAt {
                item.endAt = Calendar.current.date(byAdding: .minute, value: 15, to: item.startAt) ?? item.endAt
            }
        }
    }

    private func update(_ block: WorkBlock, edit: (inout WorkBlock) -> Void) {
        guard let index = blocks.firstIndex(where: { $0.id == block.id }) else { return }
        edit(&blocks[index])
        blocks[index].syncStatus = "대기"
        save()
        scheduleSync(block.id)
    }

    private func scheduleSync(_ id: UUID) {
        syncTasks[id]?.cancel()
        syncTasks[id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.sync(id)
        }
    }

    private func sync(_ id: UUID) async {
        guard let index = blocks.firstIndex(where: { $0.id == id }) else { return }
        blocks[index].syncStatus = "동기화 중"
        save()
        do {
            let eventId = try await eventKitManager.saveWorkBlock(blocks[index])
            if let index = blocks.firstIndex(where: { $0.id == id }) {
                blocks[index].eventIdentifier = eventId
                blocks[index].syncStatus = "동기화됨"
                message = nil
                save()
            }
        } catch {
            if let index = blocks.firstIndex(where: { $0.id == id }) {
                blocks[index].syncStatus = "실패"
                message = error.localizedDescription
                save()
            }
        }
    }

    private func snap(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        let snappedMinute = Int((Double(minute) / 15.0).rounded()) * 15
        return calendar.date(bySettingHour: components.hour ?? 0, minute: min(snappedMinute, 59), second: 0, of: date) ?? date
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WorkBlock].self, from: data) else { return }
        blocks = decoded.filter { Calendar.current.isDateInToday($0.startAt) }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(blocks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct ContentView: View {
    @StateObject private var eventKitManager = EventKitManager()
    @StateObject private var calendarSelectionStore = CalendarSelectionStore()
    @StateObject private var projectStore = ProjectStore()

    var body: some View {
        TabView {
            NavigationStack { DashboardView(eventKitManager: eventKitManager) }
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }

            NavigationStack {
                TimeView(eventKitManager: eventKitManager, calendarSelectionStore: calendarSelectionStore, projectStore: projectStore)
            }
            .tabItem { Label("Time", systemImage: "clock") }

            NavigationStack { CalendarTabView(eventKitManager: eventKitManager, selectionStore: calendarSelectionStore) }
                .tabItem { Label("Calendar", systemImage: "calendar") }

            NavigationStack { ProjectsView(selectionStore: calendarSelectionStore, projectStore: projectStore) }
                .tabItem { Label("Projects", systemImage: "folder") }

            NavigationStack { RecordView() }
                .tabItem { Label("Record", systemImage: "book.closed") }

            NavigationStack { SettingsView(eventKitManager: eventKitManager) }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

struct DashboardView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @State private var events: [CalendarEvent] = []
    @State private var message: String?

    var body: some View {
        List {
            if let message { Text(message).foregroundStyle(.secondary) }
            Section("오늘 일정") {
                if events.isEmpty {
                    Text("오늘 일정이 없습니다.").foregroundStyle(.secondary)
                } else {
                    ForEach(events) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                            Text("\(event.startAt.formatted(date: .omitted, time: .shortened)) - \(event.endAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Dashboard")
        .task { await load() }
        .toolbar { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") } }
    }

    private func load() async {
        do {
            events = try await eventKitManager.fetchEvents(on: Date(), calendarIds: [])
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
}

struct TimeView: View {
    @StateObject private var store: TimeBlockStore
    @ObservedObject var calendarSelectionStore: CalendarSelectionStore
    @ObservedObject var projectStore: ProjectStore

    @State private var title = ""
    @State private var category: ScheduleCategory = .work
    @State private var projectId: UUID?
    @State private var startAt = Date()
    @State private var endAt = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()

    init(eventKitManager: EventKitManager, calendarSelectionStore: CalendarSelectionStore, projectStore: ProjectStore) {
        _store = StateObject(wrappedValue: TimeBlockStore(eventKitManager: eventKitManager, calendarSelectionStore: calendarSelectionStore))
        self.calendarSelectionStore = calendarSelectionStore
        self.projectStore = projectStore
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("빠른 입력") {
                    TextField("일정 제목", text: $title)
                    Picker("카테고리", selection: $category) {
                        ForEach(ScheduleCategory.allCases) { item in
                            Label(item.rawValue, systemImage: item.symbol).tag(item)
                        }
                    }
                    Picker("프로젝트", selection: $projectId) {
                        Text("프로젝트 없음").tag(UUID?.none)
                        ForEach(projectStore.projects(for: category)) { project in
                            Text(project.title).tag(UUID?.some(project.id))
                        }
                    }
                    DatePicker("시작", selection: $startAt, displayedComponents: [.hourAndMinute])
                    DatePicker("종료", selection: $endAt, displayedComponents: [.hourAndMinute])
                    Button("타임블록 추가") {
                        store.create(title: title, category: category, project: projectStore.project(id: projectId), startAt: startAt, endAt: endAt)
                        title = ""
                    }
                }
            }
            .frame(maxHeight: 330)

            if let message = store.message {
                Text(message).font(.caption).foregroundStyle(.red).padding(.horizontal)
            }

            List(store.blocks) { block in
                WorkBlockRow(block: block) { delta in store.move(block, minutes: delta) } resize: { delta in store.resizeEnd(block, minutes: delta) }
            }
        }
        .navigationTitle("Time")
    }
}

struct WorkBlockRow: View {
    let block: WorkBlock
    let move: (Int) -> Void
    let resize: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(block.title).font(.headline)
                Spacer()
                Text(block.syncStatus).font(.caption)
            }
            Text("\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Label(block.category.rawValue, systemImage: block.category.symbol)
                if let projectTitle = block.projectTitle { Text(projectTitle) }
            }
            .font(.caption)
            HStack {
                Button("-15분") { move(-15) }
                Button("+15분") { move(15) }
                Button("종료 +15분") { resize(15) }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

struct CalendarTabView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @ObservedObject var selectionStore: CalendarSelectionStore
    @State private var selectedDate = Date()
    @State private var events: [CalendarEvent] = []
    @State private var showingFilter = false
    @State private var message: String?

    var body: some View {
        List {
            Section {
                HStack {
                    Button { moveDate(-1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted)).font(.headline)
                    Spacer()
                    Button { moveDate(1) } label: { Image(systemName: "chevron.right") }
                }
            }
            if let message { Text(message).foregroundStyle(.secondary) }
            Section("일정") {
                if events.isEmpty {
                    Text("선택한 캘린더에 일정이 없습니다.").foregroundStyle(.secondary)
                } else {
                    ForEach(events) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                            Text("\(event.calendarTitle) · \(event.startAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Calendar")
        .toolbar { Button { showingFilter = true } label: { Image(systemName: "line.3.horizontal.decrease.circle") } }
        .sheet(isPresented: $showingFilter) { NavigationStack { CalendarFilterView(selectionStore: selectionStore) } }
        .task { await load() }
    }

    private func moveDate(_ value: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: value, to: selectedDate) ?? selectedDate
        Task { await loadEvents() }
    }

    private func load() async {
        do {
            selectionStore.setCalendars(try await eventKitManager.fetchCalendars())
            await loadEvents()
        } catch {
            message = error.localizedDescription
        }
    }

    private func loadEvents() async {
        do {
            events = try await eventKitManager.fetchEvents(on: selectedDate, calendarIds: selectionStore.selectedIds)
            message = nil
        } catch {
            events = []
            message = error.localizedDescription
        }
    }
}

struct CalendarFilterView: View {
    @ObservedObject var selectionStore: CalendarSelectionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("카테고리 캘린더 매핑") {
                ForEach(ScheduleCategory.allCases) { category in
                    Picker(category.rawValue, selection: Binding(
                        get: { selectionStore.calendarId(for: category) },
                        set: { selectionStore.setCalendar($0, for: category) }
                    )) {
                        Text("연결 필요").tag(String?.none)
                        ForEach(selectionStore.calendars) { source in
                            Text(source.title).tag(String?.some(source.id))
                        }
                    }
                }
            }
            Section("표시할 캘린더") {
                ForEach(selectionStore.calendars) { source in
                    Toggle(source.title, isOn: Binding(
                        get: { source.isSelected },
                        set: { selectionStore.toggleCalendar(source, isSelected: $0) }
                    ))
                }
            }
        }
        .navigationTitle("Calendar Filter")
        .toolbar { Button("완료") { dismiss() } }
    }
}

struct ProjectsView: View {
    @ObservedObject var selectionStore: CalendarSelectionStore
    @ObservedObject var projectStore: ProjectStore
    @State private var title = ""
    @State private var purpose = ""
    @State private var category: ScheduleCategory = .work

    var body: some View {
        List {
            Section("프로젝트 추가") {
                TextField("프로젝트명", text: $title)
                TextField("목적", text: $purpose)
                Picker("카테고리", selection: $category) {
                    ForEach(ScheduleCategory.allCases) { item in Text(item.rawValue).tag(item) }
                }
                Text("연결 캘린더: \(selectionStore.calendarTitle(for: category))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("생성") {
                    projectStore.create(title: title, category: category, purpose: purpose, calendarIdentifier: selectionStore.calendarId(for: category))
                    title = ""
                    purpose = ""
                }
            }
            Section("Projects") {
                if projectStore.projects.isEmpty {
                    Text("프로젝트가 없습니다.").foregroundStyle(.secondary)
                } else {
                    ForEach(projectStore.projects) { project in
                        VStack(alignment: .leading) {
                            Text(project.title).font(.headline)
                            Text("\(project.category.rawValue) · \(project.purpose)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Projects")
    }
}

struct RecordView: View {
    var body: some View {
        List {
            Text("Record 탭은 다음 단계에서 하루 기록과 프로젝트 로그로 확장합니다.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Record")
    }
}

struct SettingsView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @State private var message: String?

    var body: some View {
        List {
            Section("권한 상태") {
                LabeledContent("캘린더", value: eventKitManager.calendarStatusText)
                LabeledContent("미리알림", value: eventKitManager.remindersStatusText)
            }
            Section {
                Button("캘린더 권한 요청") { Task { await requestCalendar() } }
                Button("미리알림 권한 요청") { Task { await requestReminders() } }
            }
            if let message { Text(message).foregroundStyle(.secondary) }
        }
        .navigationTitle("Settings")
    }

    private func requestCalendar() async {
        do {
            try await eventKitManager.requestCalendarAccess()
            message = "캘린더 권한이 허용되었습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func requestReminders() async {
        do {
            try await eventKitManager.requestRemindersAccess()
            message = "미리알림 권한이 허용되었습니다."
        } catch {
            message = error.localizedDescription
        }
    }
}

enum AppError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let message): return message
        }
    }
}
