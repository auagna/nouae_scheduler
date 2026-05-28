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

enum WorkBlockStatus: String, CaseIterable, Identifiable, Codable {
    case planned
    case inProgress
    case completed
    case delayed
    case stopped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planned: return "예정"
        case .inProgress: return "진행중"
        case .completed: return "완료"
        case .delayed: return "미룸"
        case .stopped: return "중단"
        }
    }
}

enum BoardViewType: String, CaseIterable, Identifiable {
    case year
    case month
    case week
    case day

    var id: String { rawValue }

    var title: String {
        switch self {
        case .year: return "Year"
        case .month: return "Month"
        case .week: return "Week"
        case .day: return "Day"
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

struct CalendarDisplayItem: Identifiable, Equatable {
    let id: String
    let title: String
    let startAt: Date
    let endAt: Date
    let sourceTitle: String
    let color: Color
    let isWorkBlock: Bool
}

struct Project: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: ScheduleCategory
    var purpose: String
    var calendarIdentifier: String?
    var createdAt = Date()
}

struct RawTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var projectId: UUID
    var title: String
    var memo: String
    var createdAt = Date()
    var isConvertedToBlock = false
}

struct ProjectLog: Identifiable, Codable, Equatable {
    var id = UUID()
    var projectId: UUID
    var title: String
    var content: String
    var focusLevel: Int?
    var blocker: String
    var nextAdjustment: String
    var createdAt = Date()

    init(id: UUID = UUID(), projectId: UUID, title: String, content: String, focusLevel: Int? = nil, blocker: String = "", nextAdjustment: String = "", createdAt: Date = Date()) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.content = content
        self.focusLevel = focusLevel
        self.blocker = blocker
        self.nextAdjustment = nextAdjustment
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, projectId, title, content, focusLevel, blocker, nextAdjustment, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        projectId = try container.decode(UUID.self, forKey: .projectId)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "기록"
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        focusLevel = try container.decodeIfPresent(Int.self, forKey: .focusLevel)
        blocker = try container.decodeIfPresent(String.self, forKey: .blocker) ?? ""
        nextAdjustment = try container.decodeIfPresent(String.self, forKey: .nextAdjustment) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

struct NextAdjustment: Identifiable, Codable, Equatable {
    var id = UUID()
    var projectId: UUID
    var content: String
    var createdAt = Date()
    var isActive = true
}

struct ProjectSummary: Equatable {
    var totalBlocks: Int
    var totalMinutes: Int
    var todayMinutes: Int
    var completedBlocks: Int
    var delayedBlocks: Int
    var stoppedBlocks: Int
    var lastWorkedAt: Date?
}

struct WorkBlock: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: ScheduleCategory
    var projectId: UUID?
    var projectTitle: String?
    var memo: String
    var startAt: Date
    var endAt: Date
    var calendarIdentifier: String?
    var eventIdentifier: String?
    var syncStatus: String
    var status: WorkBlockStatus
    var startedAt: Date?
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        category: ScheduleCategory,
        projectId: UUID? = nil,
        projectTitle: String? = nil,
        memo: String = "",
        startAt: Date,
        endAt: Date,
        calendarIdentifier: String? = nil,
        eventIdentifier: String? = nil,
        syncStatus: String = "대기",
        status: WorkBlockStatus = .planned,
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.projectId = projectId
        self.projectTitle = projectTitle
        self.memo = memo
        self.startAt = startAt
        self.endAt = endAt
        self.calendarIdentifier = calendarIdentifier
        self.eventIdentifier = eventIdentifier
        self.syncStatus = syncStatus
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    var minutes: Int {
        max(0, Int(endAt.timeIntervalSince(startAt) / 60))
    }

    var remainingSeconds: Int {
        max(0, Int(endAt.timeIntervalSince(Date())))
    }

    enum CodingKeys: String, CodingKey {
        case id, title, category, projectId, projectTitle, memo, startAt, endAt, calendarIdentifier, eventIdentifier, syncStatus, status, startedAt, completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "새 타임블록"
        category = try container.decodeIfPresent(ScheduleCategory.self, forKey: .category) ?? .work
        projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        projectTitle = try container.decodeIfPresent(String.self, forKey: .projectTitle)
        memo = try container.decodeIfPresent(String.self, forKey: .memo) ?? ""
        startAt = try container.decodeIfPresent(Date.self, forKey: .startAt) ?? Date()
        endAt = try container.decodeIfPresent(Date.self, forKey: .endAt) ?? Calendar.current.date(byAdding: .minute, value: 30, to: startAt) ?? startAt
        calendarIdentifier = try container.decodeIfPresent(String.self, forKey: .calendarIdentifier)
        eventIdentifier = try container.decodeIfPresent(String.self, forKey: .eventIdentifier)
        syncStatus = try container.decodeIfPresent(String.self, forKey: .syncStatus) ?? "대기"
        status = try container.decodeIfPresent(WorkBlockStatus.self, forKey: .status) ?? .planned
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}

@MainActor
final class EventKitManager: ObservableObject {
    @Published private(set) var calendarStatusText = "확인 필요"
    @Published private(set) var remindersStatusText = "확인 필요"

    private let eventStore = EKEventStore()

    init() { refreshAuthorizationStatus() }

    func refreshAuthorizationStatus() {
        calendarStatusText = statusText(EKEventStore.authorizationStatus(for: .event))
        remindersStatusText = statusText(EKEventStore.authorizationStatus(for: .reminder))
    }

    func requestCalendarAccess() async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        refreshAuthorizationStatus()
        if !granted { throw AppError.message("캘린더 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.") }
    }

    func requestRemindersAccess() async throws {
        let granted = try await eventStore.requestFullAccessToReminders()
        refreshAuthorizationStatus()
        if !granted { throw AppError.message("미리알림 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.") }
    }

    func fetchCalendars() async throws -> [CalendarSource] {
        try ensureCalendarAccess()
        return eventStore.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { CalendarSource(id: $0.calendarIdentifier, title: $0.title, isSelected: true) }
    }

    func fetchEvents(on date: Date, calendarIds: [String], viewType: BoardViewType = .day) async throws -> [CalendarEvent] {
        try ensureCalendarAccess()
        let interval = dateInterval(for: date, viewType: viewType)
        let calendars: [EKCalendar]? = calendarIds.isEmpty ? nil : calendarIds.compactMap { eventStore.calendar(withIdentifier: $0) }
        let predicate = eventStore.predicateForEvents(withStart: interval.start, end: interval.end, calendars: calendars)
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
            throw AppError.message("카테고리 또는 프로젝트에 연결된 Apple Calendar가 없습니다. Calendar 탭에서 연결해 주세요.")
        }
        guard block.endAt > block.startAt else { throw AppError.message("종료 시간은 시작 시간보다 늦어야 합니다.") }

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
        event.notes = "nouae category: \(block.category.rawValue)\nstatus: \(block.status.rawValue)\nprojectTitle: \(block.projectTitle ?? "")\nmemo: \(block.memo)"
        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier ?? UUID().uuidString
    }

    func createReminder(title: String, dueAt: Date) async throws {
        try ensureReminderAccess()
        guard let calendar = eventStore.defaultCalendarForNewReminders() else { throw AppError.message("기본 미리알림 목록을 찾을 수 없습니다.") }
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        reminder.calendar = calendar
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueAt)
        try eventStore.save(reminder, commit: true)
    }

    private func dateInterval(for date: Date, viewType: BoardViewType) -> DateInterval {
        let calendar = Calendar.current
        switch viewType {
        case .year:
            return calendar.dateInterval(of: .year, for: date) ?? DateInterval(start: date, duration: 365 * 24 * 3600)
        case .month:
            return calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 30 * 24 * 3600)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 24 * 3600)
        case .day:
            return calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 24 * 3600)
        }
    }

    private func ensureCalendarAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .authorized || status == .fullAccess else { throw AppError.message("캘린더 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.") }
    }

    private func ensureReminderAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .authorized || status == .fullAccess else { throw AppError.message("미리알림 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.") }
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
                if let category = ScheduleCategory(rawValue: key) { categoryMap[category] = value }
            }
        }
    }

    var selectedIds: [String] { calendars.filter(\.isSelected).map(\.id) }

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

    func selectAll() {
        for index in calendars.indices { calendars[index].isSelected = true }
        UserDefaults.standard.set(selectedIds, forKey: selectedKey)
    }

    func clearAll() {
        for index in calendars.indices { calendars[index].isSelected = false }
        UserDefaults.standard.set(selectedIds, forKey: selectedKey)
    }

    func setCalendar(_ calendarId: String?, for category: ScheduleCategory) {
        categoryMap[category] = calendarId
        saveCategoryMap()
    }

    func calendarId(for category: ScheduleCategory) -> String? { categoryMap[category] }

    func calendarTitle(for category: ScheduleCategory) -> String {
        guard let id = categoryMap[category], let source = calendars.first(where: { $0.id == id }) else { return "연결 필요" }
        return source.title
    }

    private func inferCategoryMapIfNeeded() {
        for category in ScheduleCategory.allCases where categoryMap[category] == nil {
            if let source = calendars.first(where: { source in category.calendarNames.contains { $0.caseInsensitiveCompare(source.title) == .orderedSame } }) {
                categoryMap[category] = source.id
            }
        }
        saveCategoryMap()
    }

    private func saveCategoryMap() {
        let stored = Dictionary(uniqueKeysWithValues: categoryMap.compactMap { key, value in value == nil ? nil : (key.rawValue, value!) })
        UserDefaults.standard.set(stored, forKey: categoryKey)
    }
}

@MainActor
final class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var rawTasks: [RawTask] = []
    @Published var logs: [ProjectLog] = []
    @Published var adjustments: [NextAdjustment] = []

    private let projectsKey = "stable.projects"
    private let rawTasksKey = "stable.rawTasks"
    private let logsKey = "stable.projectLogs"
    private let adjustmentsKey = "stable.nextAdjustments"

    init() {
        projects = load([Project].self, key: projectsKey) ?? []
        rawTasks = load([RawTask].self, key: rawTasksKey) ?? []
        logs = load([ProjectLog].self, key: logsKey) ?? []
        adjustments = load([NextAdjustment].self, key: adjustmentsKey) ?? []
    }

    func create(title: String, category: ScheduleCategory, purpose: String, calendarIdentifier: String?) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        projects.append(Project(title: cleanTitle, category: category, purpose: purpose, calendarIdentifier: calendarIdentifier))
        save(projects, key: projectsKey)
    }

    func projects(for category: ScheduleCategory) -> [Project] { projects.filter { $0.category == category } }
    func project(id: UUID?) -> Project? { guard let id else { return nil }; return projects.first { $0.id == id } }

    func addRawTask(project: Project, title: String, memo: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        rawTasks.append(RawTask(projectId: project.id, title: cleanTitle, memo: memo))
        save(rawTasks, key: rawTasksKey)
    }

    func rawTasks(for project: Project) -> [RawTask] {
        rawTasks.filter { $0.projectId == project.id && !$0.isConvertedToBlock }.sorted { $0.createdAt > $1.createdAt }
    }

    func addLog(project: Project, title: String, content: String, focusLevel: Int? = nil, blocker: String = "", nextAdjustment: String = "") {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty || !cleanContent.isEmpty || focusLevel != nil || !blocker.isEmpty || !nextAdjustment.isEmpty else { return }
        logs.append(ProjectLog(projectId: project.id, title: cleanTitle.isEmpty ? "기록" : cleanTitle, content: cleanContent, focusLevel: focusLevel, blocker: blocker, nextAdjustment: nextAdjustment))
        save(logs, key: logsKey)
    }

    func logs(for project: Project) -> [ProjectLog] { logs.filter { $0.projectId == project.id }.sorted { $0.createdAt > $1.createdAt } }

    func setNextAdjustment(project: Project, content: String) {
        for index in adjustments.indices where adjustments[index].projectId == project.id { adjustments[index].isActive = false }
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanContent.isEmpty else { save(adjustments, key: adjustmentsKey); return }
        adjustments.append(NextAdjustment(projectId: project.id, content: cleanContent))
        save(adjustments, key: adjustmentsKey)
    }

    func activeAdjustment(for project: Project) -> NextAdjustment? {
        adjustments.filter { $0.projectId == project.id && $0.isActive }.sorted { $0.createdAt > $1.createdAt }.first
    }

    func summary(for project: Project) -> ProjectSummary {
        let blocks = TimeBlockStore.loadPersistedBlocks().filter { $0.projectId == project.id }
        let todayBlocks = blocks.filter { Calendar.current.isDateInToday($0.startAt) }
        return ProjectSummary(
            totalBlocks: blocks.count,
            totalMinutes: blocks.reduce(0) { $0 + $1.minutes },
            todayMinutes: todayBlocks.reduce(0) { $0 + $1.minutes },
            completedBlocks: blocks.filter { $0.status == .completed }.count,
            delayedBlocks: blocks.filter { $0.status == .delayed }.count,
            stoppedBlocks: blocks.filter { $0.status == .stopped }.count,
            lastWorkedAt: blocks.map(\.endAt).max()
        )
    }

    func blocks(for project: Project) -> [WorkBlock] {
        TimeBlockStore.loadPersistedBlocks().filter { $0.projectId == project.id }.sorted { $0.startAt > $1.startAt }
    }

    func aiPrompt(for project: Project) -> String {
        let summary = summary(for: project)
        let taskText = rawTasks(for: project).map { "- \($0.title)" }.joined(separator: "\n")
        let logText = logs(for: project).prefix(5).map { "- \($0.title): \($0.content)" }.joined(separator: "\n")
        return """
        nouae Scheduler Project Brief Builder

        Project: \(project.title)
        Category: \(project.category.rawValue)
        Purpose: \(project.purpose)
        Total work: \(summary.totalMinutes) minutes
        Today work: \(summary.todayMinutes) minutes
        Completed: \(summary.completedBlocks), Delayed: \(summary.delayedBlocks), Stopped: \(summary.stoppedBlocks)
        Next adjustment: \(activeAdjustment(for: project)?.content ?? "없음")

        RawTask Inbox:
        \(taskText.isEmpty ? "없음" : taskText)

        Recent Logs:
        \(logText.isEmpty ? "없음" : logText)

        요청: 이 프로젝트의 현재 목적, 다음 작업, 조정 포인트, 리스크, 1주 액션 플랜을 간결하게 정리해줘.
        """
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
    }
}

@MainActor
final class TimeBlockStore: ObservableObject {
    @Published var blocks: [WorkBlock] = []
    @Published var message: String?

    private static let key = "stable.blocks"
    private let eventKitManager: EventKitManager
    private let calendarSelectionStore: CalendarSelectionStore
    private var syncTasks: [UUID: Task<Void, Never>] = [:]

    init(eventKitManager: EventKitManager, calendarSelectionStore: CalendarSelectionStore) {
        self.eventKitManager = eventKitManager
        self.calendarSelectionStore = calendarSelectionStore
        load()
    }

    static func loadPersistedBlocks() -> [WorkBlock] {
        guard let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([WorkBlock].self, from: data) else { return [] }
        return decoded
    }

    func visibleBlocks(for date: Date, viewType: BoardViewType) -> [WorkBlock] {
        let interval = dateInterval(for: date, viewType: viewType)
        return Self.loadPersistedBlocks()
            .filter { interval.intersects(DateInterval(start: $0.startAt, end: max($0.endAt, $0.startAt.addingTimeInterval(60)))) }
            .sorted { $0.startAt < $1.startAt }
    }

    func create(title: String, category: ScheduleCategory, project: Project?, memo: String, startAt: Date, endAt: Date) {
        let resolvedCategory = project?.category ?? category
        let snappedStart = snap(startAt)
        let block = WorkBlock(
            title: title.isEmpty ? "새 타임블록" : title,
            category: resolvedCategory,
            projectId: project?.id,
            projectTitle: project?.title,
            memo: memo,
            startAt: snappedStart,
            endAt: max(snap(endAt), Calendar.current.date(byAdding: .minute, value: 30, to: snappedStart) ?? endAt),
            calendarIdentifier: project?.calendarIdentifier ?? calendarSelectionStore.calendarId(for: resolvedCategory),
            status: .planned
        )
        blocks.append(block)
        save()
        scheduleSync(block.id)
    }

    func move(_ block: WorkBlock, minutes: Int) {
        update(block, sync: true) { item in
            item.startAt = snap(Calendar.current.date(byAdding: .minute, value: minutes, to: item.startAt) ?? item.startAt)
            item.endAt = snap(Calendar.current.date(byAdding: .minute, value: minutes, to: item.endAt) ?? item.endAt)
        }
    }

    func resizeStart(_ block: WorkBlock, minutes: Int) {
        update(block, sync: true) { item in
            let nextStart = snap(Calendar.current.date(byAdding: .minute, value: minutes, to: item.startAt) ?? item.startAt)
            if nextStart < item.endAt { item.startAt = nextStart }
        }
    }

    func resizeEnd(_ block: WorkBlock, minutes: Int) {
        update(block, sync: true) { item in
            item.endAt = snap(Calendar.current.date(byAdding: .minute, value: minutes, to: item.endAt) ?? item.endAt)
            if item.endAt <= item.startAt { item.endAt = Calendar.current.date(byAdding: .minute, value: 15, to: item.startAt) ?? item.endAt }
        }
    }

    func start(_ block: WorkBlock) { update(block, sync: false) { $0.status = .inProgress; $0.startedAt = Date() } }
    func complete(_ block: WorkBlock) { update(block, sync: false) { $0.status = .completed; $0.completedAt = Date() } }
    func delay(_ block: WorkBlock) { update(block, sync: false) { $0.status = .delayed } }
    func stop(_ block: WorkBlock) { update(block, sync: false) { $0.status = .stopped } }

    private func update(_ block: WorkBlock, sync: Bool, edit: (inout WorkBlock) -> Void) {
        guard let index = blocks.firstIndex(where: { $0.id == block.id }) else { return }
        edit(&blocks[index])
        if sync { blocks[index].syncStatus = "대기" }
        save()
        if sync { scheduleSync(block.id) }
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

    private func dateInterval(for date: Date, viewType: BoardViewType) -> DateInterval {
        let calendar = Calendar.current
        switch viewType {
        case .year: return calendar.dateInterval(of: .year, for: date) ?? DateInterval(start: date, duration: 365 * 24 * 3600)
        case .month: return calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 30 * 24 * 3600)
        case .week: return calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 24 * 3600)
        case .day: return calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 24 * 3600)
        }
    }

    private func snap(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        let snappedMinute = Int((Double(minute) / 15.0).rounded()) * 15
        return calendar.date(bySettingHour: components.hour ?? 0, minute: min(snappedMinute, 59), second: 0, of: date) ?? date
    }

    private func load() { blocks = Self.loadPersistedBlocks().filter { Calendar.current.isDateInToday($0.startAt) } }

    private func save() {
        var allBlocks = Self.loadPersistedBlocks().filter { !blocks.map(\.id).contains($0.id) }
        allBlocks.append(contentsOf: blocks)
        if let data = try? JSONEncoder().encode(allBlocks) { UserDefaults.standard.set(data, forKey: Self.key) }
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
            NavigationStack { TimeView(eventKitManager: eventKitManager, calendarSelectionStore: calendarSelectionStore, projectStore: projectStore) }
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
                if events.isEmpty { Text("오늘 일정이 없습니다.").foregroundStyle(.secondary) }
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
        .navigationTitle("Dashboard")
        .task { await load() }
        .toolbar { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") } }
    }

    private func load() async {
        do { events = try await eventKitManager.fetchEvents(on: Date(), calendarIds: [], viewType: .day); message = nil }
        catch { message = error.localizedDescription }
    }
}

struct TimeView: View {
    @StateObject private var store: TimeBlockStore
    @ObservedObject var calendarSelectionStore: CalendarSelectionStore
    @ObservedObject var projectStore: ProjectStore

    @State private var viewType: BoardViewType = .day
    @State private var selectedDate = Date()
    @State private var title = ""
    @State private var memo = ""
    @State private var category: ScheduleCategory = .work
    @State private var projectId: UUID?
    @State private var startAt = Date()
    @State private var endAt = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()

    private var visibleBlocks: [WorkBlock] { store.visibleBlocks(for: selectedDate, viewType: viewType) }
    private var activeBlock: WorkBlock? { visibleBlocks.first { $0.status == .inProgress } }
    private var startSuggestions: [WorkBlock] { visibleBlocks.filter { $0.status == .planned && Date() >= $0.startAt && Date() < $0.endAt } }
    private var closingSuggestions: [WorkBlock] { visibleBlocks.filter { $0.status == .inProgress && Date() >= $0.endAt } }

    init(eventKitManager: EventKitManager, calendarSelectionStore: CalendarSelectionStore, projectStore: ProjectStore) {
        _store = StateObject(wrappedValue: TimeBlockStore(eventKitManager: eventKitManager, calendarSelectionStore: calendarSelectionStore))
        self.calendarSelectionStore = calendarSelectionStore
        self.projectStore = projectStore
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $viewType) {
                Text("Week").tag(BoardViewType.week)
                Text("Day").tag(BoardViewType.day)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            Form {
                Section("빠른 입력") {
                    TextField("일정 제목", text: $title)
                    TextField("메모", text: $memo)
                    Picker("카테고리", selection: $category) {
                        ForEach(ScheduleCategory.allCases) { item in Label(item.rawValue, systemImage: item.symbol).tag(item) }
                    }
                    Picker("프로젝트", selection: $projectId) {
                        Text("프로젝트 없음").tag(UUID?.none)
                        ForEach(projectStore.projects(for: category)) { project in Text(project.title).tag(UUID?.some(project.id)) }
                    }
                    DatePicker("시작", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("종료", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                    Button("타임블록 추가") {
                        store.create(title: title, category: category, project: projectStore.project(id: projectId), memo: memo, startAt: startAt, endAt: endAt)
                        title = ""
                        memo = ""
                    }
                }
            }
            .frame(maxHeight: 380)

            if let message = store.message { Text(message).font(.caption).foregroundStyle(.red).padding(.horizontal) }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let activeBlock { RunningWorkPanel(block: activeBlock, store: store) }
                    ForEach(startSuggestions) { block in StartSuggestionView(block: block, store: store) }
                    ForEach(closingSuggestions) { block in ClosingSuggestionView(block: block, store: store) }

                    if viewType == .day {
                        DayTimeBoard(blocks: visibleBlocks, store: store)
                    } else {
                        WeekBlockList(blocks: visibleBlocks, store: store)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Time")
        .toolbar {
            Button { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate } label: { Image(systemName: "chevron.left") }
            Button { selectedDate = Date() } label: { Image(systemName: "dot.scope") }
            Button { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate } label: { Image(systemName: "chevron.right") }
        }
    }
}

struct RunningWorkPanel: View {
    let block: WorkBlock
    @ObservedObject var store: TimeBlockStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("진행중").font(.caption).foregroundStyle(.secondary)
            Text(block.title).font(.headline)
            Text("남은 시간 \(formatRemaining(block.remainingSeconds))")
            if let projectTitle = block.projectTitle { Text("프로젝트: \(projectTitle)").font(.caption) }
            if !block.memo.isEmpty { Text(block.memo).font(.caption).foregroundStyle(.secondary) }
            HStack {
                Button("완료") { store.complete(block) }
                Button("미룸") { store.delay(block) }
                Button("중단") { store.stop(block) }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private func formatRemaining(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes / 60)시간 \(minutes % 60)분"
    }
}

struct StartSuggestionView: View {
    let block: WorkBlock
    @ObservedObject var store: TimeBlockStore

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("시작할 시간입니다").font(.caption).foregroundStyle(.secondary)
                Text(block.title).font(.headline)
            }
            Spacer()
            Button("시작") { store.start(block) }.buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct ClosingSuggestionView: View {
    let block: WorkBlock
    @ObservedObject var store: TimeBlockStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("종료 시간이 지났습니다").font(.caption).foregroundStyle(.secondary)
            Text(block.title).font(.headline)
            HStack {
                Button("완료") { store.complete(block) }
                Button("미룸") { store.delay(block) }
                Button("중단") { store.stop(block) }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct DayTimeBoard: View {
    let blocks: [WorkBlock]
    @ObservedObject var store: TimeBlockStore
    private let hourHeight: CGFloat = 64

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimeRulerRows(hourHeight: hourHeight)
            ForEach(blocks) { block in
                WorkBlockBoardCard(block: block, store: store, hourHeight: hourHeight)
                    .padding(.leading, 62)
                    .offset(y: yOffset(block.startAt))
                    .frame(height: max(46, CGFloat(block.minutes) / 60 * hourHeight))
            }
        }
        .frame(height: CGFloat(24) * hourHeight)
    }

    private func yOffset(_ date: Date) -> CGFloat {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat(components.hour ?? 0) * hourHeight + CGFloat(components.minute ?? 0) / 60 * hourHeight
    }
}

struct TimeRulerRows: View {
    let hourHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top) {
                    Text(String(format: "%02d:00", hour)).font(.caption2).foregroundStyle(.secondary).frame(width: 50, alignment: .trailing)
                    Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
    }
}

struct WorkBlockBoardCard: View {
    let block: WorkBlock
    @ObservedObject var store: TimeBlockStore
    let hourHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Capsule().fill(Color.white.opacity(0.75)).frame(width: 42, height: 5).gesture(resizeGesture(isStart: true))
            HStack {
                Text(block.title).font(.headline).lineLimit(1)
                Spacer()
                Text(block.status.title).font(.caption2)
            }
            Text("\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened)) · \(block.syncStatus)")
                .font(.caption2)
            if let projectTitle = block.projectTitle { Text(projectTitle).font(.caption2) }
            Spacer(minLength: 0)
            Capsule().fill(Color.white.opacity(0.75)).frame(width: 42, height: 5).gesture(resizeGesture(isStart: false))
        }
        .padding(8)
        .foregroundStyle(.white)
        .background(block.category.color.gradient, in: RoundedRectangle(cornerRadius: 8))
        .gesture(moveGesture)
    }

    private var moveGesture: some Gesture {
        DragGesture().onEnded { value in
            store.move(block, minutes: snappedMinutes(for: value.translation.height))
        }
    }

    private func resizeGesture(isStart: Bool) -> some Gesture {
        DragGesture().onEnded { value in
            let minutes = snappedMinutes(for: value.translation.height)
            if isStart { store.resizeStart(block, minutes: minutes) } else { store.resizeEnd(block, minutes: minutes) }
        }
    }

    private func snappedMinutes(for translation: CGFloat) -> Int {
        let raw = translation / hourHeight * 60
        return Int((raw / 15).rounded()) * 15
    }
}

struct WeekBlockList: View {
    let blocks: [WorkBlock]
    @ObservedObject var store: TimeBlockStore

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(blocks) { block in
                WorkBlockRow(block: block, store: store)
            }
        }
    }
}

struct WorkBlockRow: View {
    let block: WorkBlock
    @ObservedObject var store: TimeBlockStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(block.title).font(.headline); Spacer(); Text(block.status.title).font(.caption) }
            Text("\(block.startAt.formatted(date: .abbreviated, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened)) · \(block.syncStatus)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button("시작") { store.start(block) }.disabled(block.status != .planned)
                Button("완료") { store.complete(block) }
                Button("미룸") { store.delay(block) }
                Button("중단") { store.stop(block) }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct CalendarTabView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @ObservedObject var selectionStore: CalendarSelectionStore
    @State private var viewType: BoardViewType = .month
    @State private var selectedDate = Date()
    @State private var events: [CalendarEvent] = []
    @State private var showingFilter = false
    @State private var message: String?

    private var workBlocks: [WorkBlock] {
        let interval = visibleInterval
        return TimeBlockStore.loadPersistedBlocks()
            .filter { interval.intersects(DateInterval(start: $0.startAt, end: max($0.endAt, $0.startAt.addingTimeInterval(60)))) }
            .sorted { $0.startAt < $1.startAt }
    }

    private var items: [CalendarDisplayItem] {
        let eventItems = events.map { event in
            CalendarDisplayItem(id: "event-\(event.id)", title: event.title, startAt: event.startAt, endAt: event.endAt, sourceTitle: event.calendarTitle, color: .blue, isWorkBlock: false)
        }
        let blockItems = workBlocks.map { block in
            CalendarDisplayItem(id: "block-\(block.id.uuidString)", title: block.title, startAt: block.startAt, endAt: block.endAt, sourceTitle: block.projectTitle ?? block.category.rawValue, color: block.category.color, isWorkBlock: true)
        }
        return (eventItems + blockItems).sorted { $0.startAt < $1.startAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            CalendarToolbar(viewType: $viewType, selectedDate: selectedDate, title: dateTitle, moveDate: moveDate)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 10)

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
            }

            Divider()

            ScrollView {
                calendarBody
                    .padding()
            }
        }
        .navigationTitle("Calendar")
        .toolbar { Button { showingFilter = true } label: { Image(systemName: "line.3.horizontal.decrease.circle") } }
        .sheet(isPresented: $showingFilter, onDismiss: { Task { await loadEvents() } }) { NavigationStack { CalendarFilterView(selectionStore: selectionStore) } }
        .task { await load() }
        .onChange(of: viewType) { _, _ in Task { await loadEvents() } }
    }

    @ViewBuilder
    private var calendarBody: some View {
        if message == nil && items.isEmpty {
            ContentUnavailableView("선택한 캘린더에 일정이 없습니다.", systemImage: "calendar.badge.exclamationmark")
        } else {
            switch viewType {
            case .day:
                CalendarDayBoard(items: items, selectedDate: selectedDate)
            case .week:
                CalendarWeekBoard(items: items, selectedDate: selectedDate)
            case .month:
                CalendarMonthBoard(items: items, selectedDate: selectedDate)
            case .year:
                CalendarYearBoard(items: items, selectedDate: selectedDate)
            }
        }
    }

    private var visibleInterval: DateInterval {
        let calendar = Calendar.current
        switch viewType {
        case .year: return calendar.dateInterval(of: .year, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 365 * 24 * 3600)
        case .month: return calendar.dateInterval(of: .month, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 30 * 24 * 3600)
        case .week: return calendar.dateInterval(of: .weekOfYear, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 7 * 24 * 3600)
        case .day: return calendar.dateInterval(of: .day, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 24 * 3600)
        }
    }

    private var dateTitle: String {
        switch viewType {
        case .year: return selectedDate.formatted(.dateTime.year())
        case .month: return selectedDate.formatted(.dateTime.year().month(.wide))
        case .week:
            let interval = visibleInterval
            return "\(interval.start.formatted(date: .abbreviated, time: .omitted)) - \(interval.end.addingTimeInterval(-1).formatted(date: .abbreviated, time: .omitted))"
        case .day: return selectedDate.formatted(date: .abbreviated, time: .omitted)
        }
    }

    private func moveDate(_ value: Int) {
        let component: Calendar.Component
        switch viewType {
        case .year: component = .year
        case .month: component = .month
        case .week: component = .weekOfYear
        case .day: component = .day
        }
        selectedDate = Calendar.current.date(byAdding: component, value: value, to: selectedDate) ?? selectedDate
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
            events = try await eventKitManager.fetchEvents(on: selectedDate, calendarIds: selectionStore.selectedIds, viewType: viewType)
            message = nil
        } catch {
            events = []
            message = error.localizedDescription
        }
    }
}

struct CalendarToolbar: View {
    @Binding var viewType: BoardViewType
    let selectedDate: Date
    let title: String
    let moveDate: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Picker("View", selection: $viewType) {
                ForEach(BoardViewType.allCases) { type in Text(type.title).tag(type) }
            }
            .pickerStyle(.segmented)

            HStack {
                Button { moveDate(-1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.bordered)
                Spacer()
                Text(title).font(.headline).multilineTextAlignment(.center)
                Spacer()
                Button { moveDate(1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.bordered)
            }
        }
    }
}

struct CalendarDayBoard: View {
    let items: [CalendarDisplayItem]
    let selectedDate: Date
    private let hourHeight: CGFloat = 64

    private var dayItems: [CalendarDisplayItem] {
        items.filter { Calendar.current.isDate($0.startAt, inSameDayAs: selectedDate) }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimeRulerRows(hourHeight: hourHeight)
            ForEach(dayItems) { item in
                CalendarTimedItemBlock(item: item)
                    .padding(.leading, 62)
                    .offset(y: yOffset(item.startAt))
                    .frame(height: max(42, height(for: item)))
            }
        }
        .frame(height: CGFloat(24) * hourHeight)
    }

    private func yOffset(_ date: Date) -> CGFloat {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat(components.hour ?? 0) * hourHeight + CGFloat(components.minute ?? 0) / 60 * hourHeight
    }

    private func height(for item: CalendarDisplayItem) -> CGFloat {
        max(15, CGFloat(item.endAt.timeIntervalSince(item.startAt) / 3600) * hourHeight)
    }
}

struct CalendarTimedItemBlock: View {
    let item: CalendarDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: item.isWorkBlock ? "cube.box" : "calendar")
                    .font(.caption2)
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            Text("\(item.startAt.formatted(date: .omitted, time: .shortened)) - \(item.endAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .lineLimit(1)
            Text(item.sourceTitle)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(7)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(item.color.gradient, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct CalendarWeekBoard: View {
    let items: [CalendarDisplayItem]
    let selectedDate: Date
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(weekDays, id: \.self) { day in
                CalendarDayColumn(day: day, items: itemsForDay(day))
            }
        }
    }

    private func itemsForDay(_ day: Date) -> [CalendarDisplayItem] {
        items.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) }
    }
}

struct CalendarDayColumn: View {
    let day: Date
    let items: [CalendarDisplayItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(day.formatted(.dateTime.day()))
                    .font(.headline)
            }
            .padding(.bottom, 4)

            if items.isEmpty {
                Text("-")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(items.prefix(6)) { item in
                    CalendarItemChip(item: item, compact: true)
                }
                if items.count > 6 {
                    Text("+\(items.count - 6)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(minHeight: 180, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct CalendarMonthBoard: View {
    let items: [CalendarDisplayItem]
    let selectedDate: Date
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var cells: [Date?] {
        let calendar = Calendar.current
        guard let month = calendar.dateInterval(of: .month, for: selectedDate),
              let range = calendar.range(of: .day, in: .month, for: selectedDate) else { return [] }
        let first = month.start
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let dates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
        return Array(repeating: nil, count: leading) + dates
    }

    var body: some View {
        VStack(spacing: 6) {
            CalendarWeekdayHeader()
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    CalendarMonthCell(date: date, items: date.map(itemsForDay) ?? [])
                }
            }
        }
    }

    private func itemsForDay(_ day: Date) -> [CalendarDisplayItem] {
        items.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) }
    }
}

struct CalendarWeekdayHeader: View {
    private let days = Calendar.current.shortWeekdaySymbols
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days, id: \.self) { day in
                Text(day)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct CalendarMonthCell: View {
    let date: Date?
    let items: [CalendarDisplayItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let date {
                Text(date.formatted(.dateTime.day()))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Calendar.current.isDateInToday(date) ? Color.accentColor : Color.primary)
                ForEach(items.prefix(3)) { item in
                    CalendarItemChip(item: item, compact: true)
                }
                if items.count > 3 {
                    Text("+\(items.count - 3)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(minHeight: 112, alignment: .topLeading)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
    }

    private var backgroundColor: Color {
        guard let date else { return Color.clear }
        return Calendar.current.isDateInToday(date) ? Color.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground)
    }
}

struct CalendarYearBoard: View {
    let items: [CalendarDisplayItem]
    let selectedDate: Date
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var months: [Date] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .year, for: selectedDate)?.start ?? selectedDate
        return (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: start) }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(months, id: \.self) { month in
                CalendarYearMonthCard(month: month, items: itemsForMonth(month))
            }
        }
    }

    private func itemsForMonth(_ month: Date) -> [CalendarDisplayItem] {
        items.filter { Calendar.current.isDate($0.startAt, equalTo: month, toGranularity: .month) }
    }
}

struct CalendarYearMonthCard: View {
    let month: Date
    let items: [CalendarDisplayItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(month.formatted(.dateTime.month(.abbreviated)))
                .font(.headline)
            Text("\(items.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(items.prefix(4)) { item in
                CalendarItemChip(item: item, compact: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(minHeight: 150, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct CalendarItemChip: View {
    let item: CalendarDisplayItem
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(item.color).frame(width: 6, height: 6)
            Text(compact ? item.title : "\(item.startAt.formatted(date: .omitted, time: .shortened)) \(item.title)")
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(item.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
    }
}

struct CalendarFilterView: View {
    @ObservedObject var selectionStore: CalendarSelectionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("카테고리 캘린더 매핑") {
                ForEach(ScheduleCategory.allCases) { category in
                    Picker(category.rawValue, selection: Binding(get: { selectionStore.calendarId(for: category) }, set: { selectionStore.setCalendar($0, for: category) })) {
                        Text("연결 필요").tag(String?.none)
                        ForEach(selectionStore.calendars) { source in Text(source.title).tag(String?.some(source.id)) }
                    }
                }
            }
            Section {
                HStack {
                    Button("전체 선택") { selectionStore.selectAll() }
                    Spacer()
                    Button("전체 해제") { selectionStore.clearAll() }
                }
            }
            Section("표시할 캘린더") {
                ForEach(selectionStore.calendars) { source in
                    Toggle(source.title, isOn: Binding(get: { source.isSelected }, set: { selectionStore.toggleCalendar(source, isSelected: $0) }))
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
                Picker("카테고리", selection: $category) { ForEach(ScheduleCategory.allCases) { item in Text(item.rawValue).tag(item) } }
                Text("연결 캘린더: \(selectionStore.calendarTitle(for: category))").font(.caption).foregroundStyle(.secondary)
                Button("생성") {
                    projectStore.create(title: title, category: category, purpose: purpose, calendarIdentifier: selectionStore.calendarId(for: category))
                    title = ""; purpose = ""
                }
            }
            Section("Projects") {
                if projectStore.projects.isEmpty { Text("프로젝트가 없습니다.").foregroundStyle(.secondary) }
                ForEach(projectStore.projects) { project in
                    NavigationLink { ProjectDetailView(project: project, projectStore: projectStore) } label: { ProjectCard(project: project, summary: projectStore.summary(for: project)) }
                }
            }
        }
        .navigationTitle("Projects")
    }
}

struct ProjectCard: View {
    let project: Project
    let summary: ProjectSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(project.title).font(.headline)
            Text("\(project.category.rawValue) · \(project.purpose)").font(.caption).foregroundStyle(.secondary)
            HStack {
                Text("오늘 \(summary.todayMinutes)분")
                Text("완료 \(summary.completedBlocks)")
                Text("중단 \(summary.stoppedBlocks)")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct ProjectDetailView: View {
    let project: Project
    @ObservedObject var projectStore: ProjectStore
    @State private var taskTitle = ""
    @State private var taskMemo = ""
    @State private var logTitle = ""
    @State private var logContent = ""
    @State private var focusLevel = 3
    @State private var blocker = ""
    @State private var nextAdjustment = ""
    @State private var adjustment = ""

    private var summary: ProjectSummary { projectStore.summary(for: project) }

    var body: some View {
        List {
            Section("Project Summary") {
                LabeledContent("카테고리", value: project.category.rawValue)
                LabeledContent("목적", value: project.purpose.isEmpty ? "미입력" : project.purpose)
                LabeledContent("오늘", value: "\(summary.todayMinutes)분")
                LabeledContent("완료", value: "\(summary.completedBlocks)개")
                LabeledContent("미룸", value: "\(summary.delayedBlocks)개")
                LabeledContent("중단", value: "\(summary.stoppedBlocks)개")
            }
            Section("Today Work") {
                let blocks = projectStore.blocks(for: project)
                if blocks.isEmpty { Text("연결된 WorkBlock이 없습니다.").foregroundStyle(.secondary) }
                ForEach(blocks) { block in
                    VStack(alignment: .leading) {
                        Text("\(block.title) · \(block.status.title)")
                        Text("\(block.startAt.formatted(date: .abbreviated, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("RawTask Inbox") {
                TextField("작업", text: $taskTitle)
                TextField("메모", text: $taskMemo)
                Button("RawTask 추가") { projectStore.addRawTask(project: project, title: taskTitle, memo: taskMemo); taskTitle = ""; taskMemo = "" }
                ForEach(projectStore.rawTasks(for: project)) { task in
                    VStack(alignment: .leading) { Text(task.title); if !task.memo.isEmpty { Text(task.memo).font(.caption).foregroundStyle(.secondary) } }
                }
            }
            Section("Recent Logs") {
                TextField("로그 제목", text: $logTitle)
                TextField("내용", text: $logContent, axis: .vertical)
                Stepper("집중도 \(focusLevel)", value: $focusLevel, in: 1...5)
                TextField("막힌 원인", text: $blocker)
                TextField("다음 조정", text: $nextAdjustment)
                Button("로그 작성") {
                    projectStore.addLog(project: project, title: logTitle, content: logContent, focusLevel: focusLevel, blocker: blocker, nextAdjustment: nextAdjustment)
                    logTitle = ""; logContent = ""; blocker = ""; nextAdjustment = ""; focusLevel = 3
                }
                ForEach(projectStore.logs(for: project)) { log in
                    VStack(alignment: .leading) {
                        Text(log.title).font(.headline)
                        Text(log.content).foregroundStyle(.secondary)
                        if let focus = log.focusLevel { Text("집중도 \(focus)/5").font(.caption2) }
                        if !log.blocker.isEmpty { Text("막힌 원인: \(log.blocker)").font(.caption2) }
                        if !log.nextAdjustment.isEmpty { Text("다음 조정: \(log.nextAdjustment)").font(.caption2) }
                    }
                }
            }
            Section("Next Adjustment") {
                TextField("다음 조정", text: $adjustment, axis: .vertical)
                Button("저장") { projectStore.setNextAdjustment(project: project, content: adjustment); adjustment = "" }
                if let active = projectStore.activeAdjustment(for: project) { Text(active.content).foregroundStyle(.secondary) }
            }
            Section("AI Brief Prompt Export") { ShareLink(item: projectStore.aiPrompt(for: project)) { Label("프롬프트 공유/복사", systemImage: "square.and.arrow.up") } }
        }
        .navigationTitle(project.title)
    }
}

struct RecordView: View {
    var body: some View {
        List { Text("Record 탭은 다음 단계에서 Closing Report와 하루 기록으로 확장합니다.").foregroundStyle(.secondary) }
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
        do { try await eventKitManager.requestCalendarAccess(); message = "캘린더 권한이 허용되었습니다." }
        catch { message = error.localizedDescription }
    }

    private func requestReminders() async {
        do { try await eventKitManager.requestRemindersAccess(); message = "미리알림 권한이 허용되었습니다." }
        catch { message = error.localizedDescription }
    }
}

enum AppError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let message) = self { return message }; return nil }
}
