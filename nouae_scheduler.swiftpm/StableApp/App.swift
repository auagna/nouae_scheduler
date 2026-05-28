import EventKit
import SwiftUI
import UIKit

@main
struct NouAESchedulerApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
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
    var title: String { rawValue.capitalized }
}

enum TodayLayoutMode: String, CaseIterable, Identifiable {
    case verticalSplit
    case horizontalSplit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .verticalSplit: return "Vertical"
        case .horizontalSplit: return "Horizontal"
        }
    }

    static var defaultMode: TodayLayoutMode {
        UIDevice.current.userInterfaceIdiom == .pad ? .horizontalSplit : .verticalSplit
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

struct CalendarDisplayItem: Identifiable {
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
    var title: String
    var memo: String
    var category: ScheduleCategory
    var projectId: UUID?
    var createdAt = Date()
    var dueAt: Date?
    var repeatRule: String?
    var isConvertedToBlock = false

    init(
        id: UUID = UUID(),
        title: String,
        memo: String = "",
        category: ScheduleCategory = .work,
        projectId: UUID? = nil,
        createdAt: Date = Date(),
        dueAt: Date? = nil,
        repeatRule: String? = nil,
        isConvertedToBlock: Bool = false
    ) {
        self.id = id
        self.title = title
        self.memo = memo
        self.category = category
        self.projectId = projectId
        self.createdAt = createdAt
        self.dueAt = dueAt
        self.repeatRule = repeatRule
        self.isConvertedToBlock = isConvertedToBlock
    }

    enum CodingKeys: String, CodingKey {
        case id, title, memo, category, projectId, createdAt, dueAt, repeatRule, isConvertedToBlock
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "새 작업"
        memo = try container.decodeIfPresent(String.self, forKey: .memo) ?? ""
        category = try container.decodeIfPresent(ScheduleCategory.self, forKey: .category) ?? .work
        projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
        repeatRule = try container.decodeIfPresent(String.self, forKey: .repeatRule)
        isConvertedToBlock = try container.decodeIfPresent(Bool.self, forKey: .isConvertedToBlock) ?? false
    }
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
}

struct NextAdjustment: Identifiable, Codable, Equatable {
    var id = UUID()
    var projectId: UUID
    var content: String
    var createdAt = Date()
    var isActive = true
}

struct ProjectSummary {
    var totalBlocks: Int
    var totalMinutes: Int
    var todayMinutes: Int
    var completedBlocks: Int
    var delayedBlocks: Int
    var stoppedBlocks: Int
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

    var minutes: Int { max(0, Int(endAt.timeIntervalSince(startAt) / 60)) }
    var remainingSeconds: Int { max(0, Int(endAt.timeIntervalSince(Date()))) }

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

    func fetchEvents(on date: Date, calendarIds: [String], viewType: BoardViewType) async throws -> [CalendarEvent] {
        try ensureCalendarAccess()
        let interval = DateHelper.interval(for: date, viewType: viewType)
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
        if let eventIdentifier = block.eventIdentifier, let existing = eventStore.event(withIdentifier: eventIdentifier) {
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

    private func ensureCalendarAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .authorized || status == .fullAccess else { throw AppError.message("캘린더 권한이 없습니다. Profile 탭에서 권한을 요청해 주세요.") }
    }

    private func ensureReminderAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .authorized || status == .fullAccess else { throw AppError.message("미리알림 권한이 없습니다. Profile 탭에서 권한을 요청해 주세요.") }
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
        let stored = Dictionary(uniqueKeysWithValues: categoryMap.map { ($0.key.rawValue, $0.value) })
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
    func task(id: UUID) -> RawTask? { rawTasks.first { $0.id == id } }

    func addRawTask(title: String, memo: String, category: ScheduleCategory, projectId: UUID?) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        rawTasks.append(RawTask(title: cleanTitle, memo: memo, category: category, projectId: projectId))
        save(rawTasks, key: rawTasksKey)
    }

    func rawInbox() -> [RawTask] {
        rawTasks.filter { !$0.isConvertedToBlock }.sorted { $0.createdAt > $1.createdAt }
    }

    func rawTasks(for project: Project) -> [RawTask] {
        rawTasks.filter { $0.projectId == project.id && !$0.isConvertedToBlock }.sorted { $0.createdAt > $1.createdAt }
    }

    func markRawTaskConverted(_ id: UUID) {
        guard let index = rawTasks.firstIndex(where: { $0.id == id }) else { return }
        rawTasks[index].isConvertedToBlock = true
        save(rawTasks, key: rawTasksKey)
    }

    func addLog(project: Project, title: String, content: String, focusLevel: Int? = nil, blocker: String = "", nextAdjustment: String = "") {
        guard !title.isEmpty || !content.isEmpty || focusLevel != nil || !blocker.isEmpty || !nextAdjustment.isEmpty else { return }
        logs.append(ProjectLog(projectId: project.id, title: title.isEmpty ? "기록" : title, content: content, focusLevel: focusLevel, blocker: blocker, nextAdjustment: nextAdjustment))
        save(logs, key: logsKey)
    }

    func logs(for project: Project) -> [ProjectLog] { logs.filter { $0.projectId == project.id }.sorted { $0.createdAt > $1.createdAt } }

    func setNextAdjustment(project: Project, content: String) {
        for index in adjustments.indices where adjustments[index].projectId == project.id { adjustments[index].isActive = false }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { save(adjustments, key: adjustmentsKey); return }
        adjustments.append(NextAdjustment(projectId: project.id, content: content))
        save(adjustments, key: adjustmentsKey)
    }

    func activeAdjustment(for project: Project) -> NextAdjustment? {
        adjustments.filter { $0.projectId == project.id && $0.isActive }.sorted { $0.createdAt > $1.createdAt }.first
    }

    func activeAdjustments() -> [(Project, NextAdjustment)] {
        adjustments.filter(\.isActive).compactMap { adjustment in
            guard let project = project(id: adjustment.projectId) else { return nil }
            return (project, adjustment)
        }
        .sorted { $0.1.createdAt > $1.1.createdAt }
    }

    func blocks(for project: Project) -> [WorkBlock] {
        TimeBlockStore.loadPersistedBlocks().filter { $0.projectId == project.id }.sorted { $0.startAt > $1.startAt }
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
            stoppedBlocks: blocks.filter { $0.status == .stopped }.count
        )
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
        blocks = Self.loadPersistedBlocks().filter { Calendar.current.isDateInToday($0.startAt) }
    }

    static func loadPersistedBlocks() -> [WorkBlock] {
        guard let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([WorkBlock].self, from: data) else { return [] }
        return decoded
    }

    func visibleBlocks(for date: Date, viewType: BoardViewType) -> [WorkBlock] {
        let interval = DateHelper.interval(for: date, viewType: viewType)
        return Self.loadPersistedBlocks()
            .filter { interval.intersects(DateInterval(start: $0.startAt, end: max($0.endAt, $0.startAt.addingTimeInterval(60)))) }
            .sorted { $0.startAt < $1.startAt }
    }

    func create(title: String, category: ScheduleCategory, project: Project?, memo: String, startAt: Date, endAt: Date) {
        let resolvedCategory = project?.category ?? category
        let snappedStart = DateHelper.snap(startAt)
        let block = WorkBlock(
            title: title.isEmpty ? "새 타임블록" : title,
            category: resolvedCategory,
            projectId: project?.id,
            projectTitle: project?.title,
            memo: memo,
            startAt: snappedStart,
            endAt: max(DateHelper.snap(endAt), Calendar.current.date(byAdding: .minute, value: 30, to: snappedStart) ?? endAt),
            calendarIdentifier: project?.calendarIdentifier ?? calendarSelectionStore.calendarId(for: resolvedCategory),
            status: .planned
        )
        blocks.append(block)
        save()
        scheduleSync(block.id)
    }

    func move(_ block: WorkBlock, minutes: Int) {
        update(block, sync: true) {
            $0.startAt = DateHelper.snap(Calendar.current.date(byAdding: .minute, value: minutes, to: $0.startAt) ?? $0.startAt)
            $0.endAt = DateHelper.snap(Calendar.current.date(byAdding: .minute, value: minutes, to: $0.endAt) ?? $0.endAt)
        }
    }

    func resizeStart(_ block: WorkBlock, minutes: Int) {
        update(block, sync: true) {
            let next = DateHelper.snap(Calendar.current.date(byAdding: .minute, value: minutes, to: $0.startAt) ?? $0.startAt)
            if next < $0.endAt { $0.startAt = next }
        }
    }

    func resizeEnd(_ block: WorkBlock, minutes: Int) {
        update(block, sync: true) {
            $0.endAt = DateHelper.snap(Calendar.current.date(byAdding: .minute, value: minutes, to: $0.endAt) ?? $0.endAt)
            if $0.endAt <= $0.startAt { $0.endAt = Calendar.current.date(byAdding: .minute, value: 10, to: $0.startAt) ?? $0.endAt }
        }
    }

    func start(_ block: WorkBlock) { update(block, sync: false) { $0.status = .inProgress; $0.startedAt = Date() } }
    func complete(_ block: WorkBlock) { update(block, sync: false) { $0.status = .completed; $0.completedAt = Date() } }
    func delay(_ block: WorkBlock) { update(block, sync: false) { $0.status = .delayed } }
    func stop(_ block: WorkBlock) { update(block, sync: false) { $0.status = .stopped } }

    private func update(_ block: WorkBlock, sync: Bool, edit: (inout WorkBlock) -> Void) {
        if !blocks.contains(where: { $0.id == block.id }) { blocks.append(block) }
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

    private func save() {
        let currentIds = Set(blocks.map(\.id))
        var allBlocks = Self.loadPersistedBlocks().filter { !currentIds.contains($0.id) }
        allBlocks.append(contentsOf: blocks)
        if let data = try? JSONEncoder().encode(allBlocks) { UserDefaults.standard.set(data, forKey: Self.key) }
    }
}

enum DateHelper {
    static func interval(for date: Date, viewType: BoardViewType) -> DateInterval {
        let calendar = Calendar.current
        switch viewType {
        case .year: return calendar.dateInterval(of: .year, for: date) ?? DateInterval(start: date, duration: 365 * 24 * 3600)
        case .month: return calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 30 * 24 * 3600)
        case .week: return calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 24 * 3600)
        case .day: return calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 24 * 3600)
        }
    }

    static func snap(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minute = components.minute ?? 0
        let snappedMinute = Int((Double(minute) / 10.0).rounded()) * 10
        return calendar.date(bySettingHour: components.hour ?? 0, minute: min(snappedMinute, 59), second: 0, of: date) ?? date
    }

    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func date(on day: Date, minutesFromMidnight: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutesFromMidnight, to: startOfDay(day)) ?? day
    }
}

struct ContentView: View {
    @StateObject private var eventKitManager = EventKitManager()
    @StateObject private var calendarSelectionStore = CalendarSelectionStore()
    @StateObject private var projectStore = ProjectStore()

    var body: some View {
        TabView {
            NavigationStack { DashboardView(eventKitManager: eventKitManager, projectStore: projectStore) }
                .tabItem { Label("Dashboard", systemImage: "chart.bar.doc.horizontal") }
            NavigationStack { TodayView(eventKitManager: eventKitManager, calendarSelectionStore: calendarSelectionStore, projectStore: projectStore) }
                .tabItem { Label("Today", systemImage: "square.and.pencil") }
            NavigationStack { CalendarTabView(eventKitManager: eventKitManager, selectionStore: calendarSelectionStore) }
                .tabItem { Label("Calendar", systemImage: "calendar") }
            NavigationStack { ProjectsView(selectionStore: calendarSelectionStore, projectStore: projectStore) }
                .tabItem { Label("Projects", systemImage: "folder") }
            NavigationStack { LogView(projectStore: projectStore) }
                .tabItem { Label("Log", systemImage: "book.closed") }
            NavigationStack { ProfileView(eventKitManager: eventKitManager) }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

struct DashboardView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @ObservedObject var projectStore: ProjectStore
    @State private var events: [CalendarEvent] = []
    @State private var message: String?

    private var todayBlocks: [WorkBlock] { TimeBlockStore.loadPersistedBlocks().filter { Calendar.current.isDateInToday($0.startAt) } }
    private var unfinishedBlocks: [WorkBlock] { todayBlocks.filter { $0.status == .planned || $0.status == .inProgress || $0.status == .delayed } }
    private var activeProjects: [Project] { projectStore.projects.filter { projectStore.summary(for: $0).todayMinutes > 0 || projectStore.rawTasks(for: $0).isEmpty == false } }
    private var coreBlocks: [WorkBlock] { todayBlocks.filter { $0.status == .planned || $0.status == .inProgress }.prefix(5).map { $0 } }

    var body: some View {
        List {
            Section("오늘 브리핑") {
                Text(briefingText)
                    .font(.headline)
            }
            Section("오늘 상태 요약") {
                LabeledContent("Apple Calendar 일정", value: "\(events.count)개")
                LabeledContent("nouae WorkBlock", value: "\(todayBlocks.count)개")
                LabeledContent("미완료", value: "\(unfinishedBlocks.count)개")
                if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
            }
            Section("오늘 진행 중 프로젝트") {
                if activeProjects.isEmpty { Text("오늘 움직이는 프로젝트가 아직 없습니다.").foregroundStyle(.secondary) }
                ForEach(Array(activeProjects.prefix(5))) { project in
                    let summary = projectStore.summary(for: project)
                    VStack(alignment: .leading) {
                        Text(project.title).font(.headline)
                        Text("\(project.category.rawValue) · 오늘 \(summary.todayMinutes)분 · RawTask \(projectStore.rawTasks(for: project).count)개")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("오늘 핵심 WorkBlock") {
                if coreBlocks.isEmpty { Text("Today에서 블록을 배치하면 여기에 올라옵니다.").foregroundStyle(.secondary) }
                ForEach(coreBlocks) { block in WorkBlockSummaryRow(block: block) }
            }
            Section("미완료 작업 요약") {
                LabeledContent("RawTask Inbox", value: "\(projectStore.rawInbox().count)개")
                LabeledContent("Delayed", value: "\(TimeBlockStore.loadPersistedBlocks().filter { $0.status == .delayed }.count)개")
            }
            Section("최근 Next Adjustment") {
                let adjustments = projectStore.activeAdjustments()
                if adjustments.isEmpty { Text("최근 조정 메모가 없습니다.").foregroundStyle(.secondary) }
                ForEach(Array(adjustments.prefix(5)), id: \.1.id) { project, adjustment in
                    VStack(alignment: .leading) {
                        Text(project.title).font(.headline)
                        Text(adjustment.content).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Weather Context") {
                Text("외부 API는 사용하지 않습니다. 날씨 판단이 필요하면 Apple Weather 앱을 확인하고 Today 배치에 반영하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Closing Report Preview") {
                Text("완료 \(todayBlocks.filter { $0.status == .completed }.count)개 · 미룸 \(todayBlocks.filter { $0.status == .delayed }.count)개 · 중단 \(todayBlocks.filter { $0.status == .stopped }.count)개")
            }
        }
        .navigationTitle("Dashboard")
        .task { await load() }
        .toolbar { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") } }
    }

    private var briefingText: String {
        "오늘은 RawTask를 Today에 쏟아내고, 핵심 WorkBlock \(coreBlocks.count)개를 시간 위에 고정하는 날입니다."
    }

    private func load() async {
        do { events = try await eventKitManager.fetchEvents(on: Date(), calendarIds: [], viewType: .day); message = nil }
        catch { message = error.localizedDescription }
    }
}

struct TodayView: View {
    @StateObject private var store: TimeBlockStore
    @ObservedObject var projectStore: ProjectStore
    @AppStorage("stable.today.layoutMode") private var layoutModeRaw = ""
    @State private var boardViewType: BoardViewType = .day
    @State private var selectedDate = Date()
    @State private var rawTitle = ""
    @State private var rawMemo = ""
    @State private var rawCategory: ScheduleCategory = .work
    @State private var rawProjectId: UUID?

    private var layoutMode: TodayLayoutMode { TodayLayoutMode(rawValue: layoutModeRaw) ?? TodayLayoutMode.defaultMode }
    private var visibleBlocks: [WorkBlock] { store.visibleBlocks(for: selectedDate, viewType: boardViewType) }
    private var yesterdayUnfinished: [WorkBlock] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return TimeBlockStore.loadPersistedBlocks().filter { Calendar.current.isDate($0.startAt, inSameDayAs: yesterday) && $0.status != .completed }
    }
    private var delayedTasks: [WorkBlock] { TimeBlockStore.loadPersistedBlocks().filter { $0.status == .delayed }.sorted { $0.startAt > $1.startAt } }

    init(eventKitManager: EventKitManager, calendarSelectionStore: CalendarSelectionStore, projectStore: ProjectStore) {
        _store = StateObject(wrappedValue: TimeBlockStore(eventKitManager: eventKitManager, calendarSelectionStore: calendarSelectionStore))
        self.projectStore = projectStore
    }

    var body: some View {
        GeometryReader { proxy in
            if layoutMode == .horizontalSplit {
                HStack(spacing: 0) {
                    ScrollView { leftPanel.padding() }
                        .frame(width: max(330, proxy.size.width * 0.34))
                    Divider()
                    ScrollView { rightPanel.padding() }
                }
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        leftPanel
                        rightPanel
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Today")
        .toolbar {
            Picker("Layout", selection: Binding(get: { layoutMode }, set: { layoutModeRaw = $0.rawValue })) {
                ForEach(TodayLayoutMode.allCases) { mode in Text(mode.title).tag(mode) }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
        }
    }

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupBox("Quick Capture") {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("머릿속 작업을 빠르게 입력", text: $rawTitle)
                    TextField("메모", text: $rawMemo, axis: .vertical)
                    Picker("Category", selection: $rawCategory) {
                        ForEach(ScheduleCategory.allCases) { category in Text(category.rawValue).tag(category) }
                    }
                    Picker("Project", selection: $rawProjectId) {
                        Text("프로젝트 없음").tag(UUID?.none)
                        ForEach(projectStore.projects(for: rawCategory)) { project in Text(project.title).tag(UUID?.some(project.id)) }
                    }
                    Button { addRawTask() } label: { Label("RawTask 추가", systemImage: "plus") }
                        .buttonStyle(.borderedProminent)
                }
            }

            GroupBox("RawTask Inbox") {
                VStack(alignment: .leading, spacing: 8) {
                    if projectStore.rawInbox().isEmpty { Text("입력된 RawTask가 없습니다.").foregroundStyle(.secondary) }
                    ForEach(projectStore.rawInbox()) { task in
                        RawTaskCard(task: task, project: projectStore.project(id: task.projectId))
                            .draggable(task.id.uuidString)
                    }
                }
            }

            GroupBox("Yesterday Unfinished") {
                VStack(alignment: .leading, spacing: 8) {
                    if yesterdayUnfinished.isEmpty { Text("어제 미완료 블록이 없습니다.").foregroundStyle(.secondary) }
                    ForEach(yesterdayUnfinished) { WorkBlockSummaryRow(block: $0) }
                }
            }

            GroupBox("Delayed Tasks") {
                VStack(alignment: .leading, spacing: 8) {
                    if delayedTasks.isEmpty { Text("미룬 작업이 없습니다.").foregroundStyle(.secondary) }
                    ForEach(delayedTasks.prefix(8)) { WorkBlockSummaryRow(block: $0) }
                }
            }
        }
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupBox("Calendar Board") {
                VStack(spacing: 10) {
                    HStack {
                        Button { moveDate(-1) } label: { Image(systemName: "chevron.left") }
                            .buttonStyle(.bordered)
                        Spacer()
                        Text(boardTitle).font(.headline)
                        Spacer()
                        Button { moveDate(1) } label: { Image(systemName: "chevron.right") }
                            .buttonStyle(.bordered)
                    }
                    Picker("View", selection: $boardViewType) {
                        Text("Day").tag(BoardViewType.day)
                        Text("Week").tag(BoardViewType.week)
                        Text("Month").tag(BoardViewType.month)
                    }
                    .pickerStyle(.segmented)

                    switch boardViewType {
                    case .day:
                        TodayDayBoard(blocks: visibleBlocks, selectedDate: selectedDate, store: store, onDropTask: placeRawTask)
                    case .week:
                        TodayWeekBoard(blocks: visibleBlocks, selectedDate: selectedDate, store: store, onDropTask: placeRawTask)
                    case .month:
                        TodayMonthBoard(blocks: visibleBlocks, selectedDate: selectedDate, onDropTask: placeRawTask)
                    case .year:
                        EmptyView()
                    }
                }
            }

            GroupBox("WorkBlock Timeline") {
                VStack(alignment: .leading, spacing: 8) {
                    if visibleBlocks.isEmpty { Text("배치된 WorkBlock이 없습니다.").foregroundStyle(.secondary) }
                    ForEach(visibleBlocks) { block in WorkBlockRow(block: block, store: store) }
                }
            }

            if let message = store.message {
                Text(message).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private var boardTitle: String {
        switch boardViewType {
        case .day: return selectedDate.formatted(date: .abbreviated, time: .omitted)
        case .week:
            let interval = DateHelper.interval(for: selectedDate, viewType: .week)
            return "\(interval.start.formatted(date: .abbreviated, time: .omitted)) - \(interval.end.addingTimeInterval(-1).formatted(date: .abbreviated, time: .omitted))"
        case .month: return selectedDate.formatted(.dateTime.year().month(.wide))
        case .year: return selectedDate.formatted(.dateTime.year())
        }
    }

    private func addRawTask() {
        projectStore.addRawTask(title: rawTitle, memo: rawMemo, category: rawCategory, projectId: rawProjectId)
        rawTitle = ""
        rawMemo = ""
    }

    private func moveDate(_ value: Int) {
        let component: Calendar.Component = boardViewType == .month ? .month : boardViewType == .week ? .weekOfYear : .day
        selectedDate = Calendar.current.date(byAdding: component, value: value, to: selectedDate) ?? selectedDate
    }

    private func placeRawTask(_ taskId: String, startAt: Date) {
        guard let uuid = UUID(uuidString: taskId), let task = projectStore.task(id: uuid) else { return }
        let project = projectStore.project(id: task.projectId)
        let endAt = Calendar.current.date(byAdding: .minute, value: boardViewType == .month ? 60 : 30, to: startAt) ?? startAt
        store.create(title: task.title, category: task.category, project: project, memo: task.memo, startAt: startAt, endAt: endAt)
        projectStore.markRawTaskConverted(uuid)
    }
}

struct RawTaskCard: View {
    let task: RawTask
    let project: Project?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
                Text(task.title).font(.headline)
                Spacer()
                Text(task.category.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(task.category.color.opacity(0.14), in: Capsule())
            }
            if !task.memo.isEmpty { Text(task.memo).font(.caption).foregroundStyle(.secondary) }
            if let project { Text(project.title).font(.caption2).foregroundStyle(.secondary) }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct TodayDayBoard: View {
    let blocks: [WorkBlock]
    let selectedDate: Date
    @ObservedObject var store: TimeBlockStore
    let onDropTask: (String, Date) -> Void
    private let hourHeight: CGFloat = 68

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimeRulerRows(hourHeight: hourHeight)
            ForEach(blocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: selectedDate) }) { block in
                EditableWorkBlockCard(block: block, store: store, hourHeight: hourHeight)
                    .padding(.leading, 62)
                    .offset(y: yOffset(block.startAt))
                    .frame(height: max(48, CGFloat(block.minutes) / 60 * hourHeight))
            }
        }
        .frame(height: CGFloat(24) * hourHeight)
        .dropDestination(for: String.self) { ids, location in
            let startAt = date(for: location.y)
            ids.forEach { onDropTask($0, startAt) }
            return !ids.isEmpty
        }
    }

    private func yOffset(_ date: Date) -> CGFloat {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat(c.hour ?? 0) * hourHeight + CGFloat(c.minute ?? 0) / 60 * hourHeight
    }

    private func date(for y: CGFloat) -> Date {
        let rawMinutes = max(0, min(24 * 60 - 10, Int((y / hourHeight) * 60)))
        let snapped = Int((Double(rawMinutes) / 10.0).rounded()) * 10
        return DateHelper.date(on: selectedDate, minutesFromMidnight: snapped)
    }
}

struct TodayWeekBoard: View {
    let blocks: [WorkBlock]
    let selectedDate: Date
    @ObservedObject var store: TimeBlockStore
    let onDropTask: (String, Date) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var weekDays: [Date] {
        let start = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(weekDays, id: \.self) { day in
                TodayWeekDayColumn(day: day, blocks: blocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) }, store: store, onDropTask: onDropTask)
            }
        }
    }
}

struct TodayWeekDayColumn: View {
    let day: Date
    let blocks: [WorkBlock]
    @ObservedObject var store: TimeBlockStore
    let onDropTask: (String, Date) -> Void
    private let hourHeight: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(day.formatted(.dateTime.weekday(.abbreviated))).font(.caption2).foregroundStyle(.secondary)
            Text(day.formatted(.dateTime.day())).font(.headline)
            ZStack(alignment: .topLeading) {
                TimeRulerRows(hourHeight: hourHeight)
                    .opacity(0.45)
                ForEach(blocks) { block in
                    MiniEditableWorkBlock(block: block, store: store, hourHeight: hourHeight)
                        .padding(.leading, 28)
                        .offset(y: yOffset(block.startAt))
                        .frame(height: max(26, CGFloat(block.minutes) / 60 * hourHeight))
                }
            }
            .frame(height: CGFloat(24) * hourHeight)
            .dropDestination(for: String.self) { ids, location in
                let startAt = date(for: location.y)
                ids.forEach { onDropTask($0, startAt) }
                return !ids.isEmpty
            }
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func yOffset(_ date: Date) -> CGFloat {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat(c.hour ?? 0) * hourHeight + CGFloat(c.minute ?? 0) / 60 * hourHeight
    }

    private func date(for y: CGFloat) -> Date {
        let rawMinutes = max(0, min(24 * 60 - 10, Int((y / hourHeight) * 60)))
        let snapped = Int((Double(rawMinutes) / 10.0).rounded()) * 10
        return DateHelper.date(on: day, minutesFromMidnight: snapped)
    }
}

struct TodayMonthBoard: View {
    let blocks: [WorkBlock]
    let selectedDate: Date
    let onDropTask: (String, Date) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var cells: [Date?] {
        let calendar = Calendar.current
        guard let month = calendar.dateInterval(of: .month, for: selectedDate), let range = calendar.range(of: .day, in: .month, for: selectedDate) else { return [] }
        let first = month.start
        let leading = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        let dates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
        return Array(repeating: nil, count: leading) + dates
    }

    var body: some View {
        VStack(spacing: 6) {
            CalendarWeekdayHeader()
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    TodayMonthCell(date: date, blocks: date.map(blocksForDay) ?? [], onDropTask: onDropTask)
                }
            }
        }
    }

    private func blocksForDay(_ day: Date) -> [WorkBlock] {
        blocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) }
    }
}

struct TodayMonthCell: View {
    let date: Date?
    let blocks: [WorkBlock]
    let onDropTask: (String, Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let date {
                Text(date.formatted(.dateTime.day()))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Calendar.current.isDateInToday(date) ? Color.accentColor : Color.primary)
                ForEach(blocks.prefix(3)) { block in
                    Text(block.title)
                        .font(.caption2)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(block.category.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
                }
                if blocks.count > 3 { Text("+\(blocks.count - 3)").font(.caption2).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(minHeight: 112, alignment: .topLeading)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .dropDestination(for: String.self) { ids, _ in
            guard let date else { return false }
            let start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
            ids.forEach { onDropTask($0, start) }
            return !ids.isEmpty
        }
    }

    private var backgroundColor: Color {
        guard let date else { return Color.clear }
        return Calendar.current.isDateInToday(date) ? Color.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground)
    }
}

struct TimeRulerRows: View {
    let hourHeight: CGFloat
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top) {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .trailing)
                    Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
    }
}

struct EditableWorkBlockCard: View {
    let block: WorkBlock
    @ObservedObject var store: TimeBlockStore
    let hourHeight: CGFloat
    @GestureState private var moveOffset: CGFloat = 0
    @GestureState private var topResizeOffset: CGFloat = 0
    @GestureState private var bottomResizeOffset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Capsule().fill(Color.white.opacity(0.8)).frame(width: 44, height: 5).gesture(resizeGesture(isStart: true))
            HStack { Text(block.title).font(.headline).lineLimit(1); Spacer(); Text(block.status.title).font(.caption2) }
            Text("\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened)) · \(block.syncStatus)").font(.caption2)
            if let projectTitle = block.projectTitle { Text(projectTitle).font(.caption2) }
            Spacer(minLength: 0)
            Capsule().fill(Color.white.opacity(0.8)).frame(width: 44, height: 5).gesture(resizeGesture(isStart: false))
        }
        .padding(8)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: adjustedHeight, alignment: .topLeading)
        .background(block.category.color.gradient, in: RoundedRectangle(cornerRadius: 8))
        .offset(y: moveOffset + topResizeOffset)
        .animation(.spring(response: 0.22, dampingFraction: 0.86), value: moveOffset)
        .animation(.spring(response: 0.22, dampingFraction: 0.86), value: topResizeOffset)
        .gesture(moveGesture)
    }

    private var adjustedHeight: CGFloat {
        max(42, CGFloat(block.minutes) / 60 * hourHeight - topResizeOffset + bottomResizeOffset)
    }

    private var moveGesture: some Gesture {
        DragGesture()
            .updating($moveOffset) { value, state, _ in state = value.translation.height }
            .onEnded { value in store.move(block, minutes: snappedMinutes(for: value.translation.height)) }
    }

    private func resizeGesture(isStart: Bool) -> some Gesture {
        DragGesture()
            .updating(isStart ? $topResizeOffset : $bottomResizeOffset) { value, state, _ in state = value.translation.height }
            .onEnded { value in
                let minutes = snappedMinutes(for: value.translation.height)
                if isStart { store.resizeStart(block, minutes: minutes) } else { store.resizeEnd(block, minutes: minutes) }
            }
    }

    private func snappedMinutes(for translation: CGFloat) -> Int {
        Int(((translation / hourHeight * 60) / 10).rounded()) * 10
    }
}

struct MiniEditableWorkBlock: View {
    let block: WorkBlock
    @ObservedObject var store: TimeBlockStore
    let hourHeight: CGFloat
    @GestureState private var offset: CGFloat = 0

    var body: some View {
        Text(block.title)
            .font(.caption2.weight(.semibold))
            .lineLimit(2)
            .padding(5)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(block.category.color, in: RoundedRectangle(cornerRadius: 5))
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .updating($offset) { value, state, _ in state = value.translation.height }
                    .onEnded { value in store.move(block, minutes: Int(((value.translation.height / hourHeight * 60) / 10).rounded()) * 10) }
            )
    }
}

struct WorkBlockSummaryRow: View {
    let block: WorkBlock
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack { Text(block.title).font(.headline); Spacer(); Text(block.status.title).font(.caption) }
            Text("\(block.startAt.formatted(date: .abbreviated, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let projectTitle = block.projectTitle { Text(projectTitle).font(.caption2).foregroundStyle(.secondary) }
        }
    }
}

struct WorkBlockRow: View {
    let block: WorkBlock
    @ObservedObject var store: TimeBlockStore
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(block.title).font(.headline); Spacer(); Text(block.status.title).font(.caption) }
            Text("\(block.startAt.formatted(date: .abbreviated, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened)) · \(block.syncStatus)").font(.caption).foregroundStyle(.secondary)
            HStack { Button("시작") { store.start(block) }.disabled(block.status != .planned); Button("완료") { store.complete(block) }; Button("미룸") { store.delay(block) }; Button("중단") { store.stop(block) } }
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

    private var visibleInterval: DateInterval { DateHelper.interval(for: selectedDate, viewType: viewType) }

    private var workBlocks: [WorkBlock] {
        TimeBlockStore.loadPersistedBlocks()
            .filter { visibleInterval.intersects(DateInterval(start: $0.startAt, end: max($0.endAt, $0.startAt.addingTimeInterval(60)))) }
            .sorted { $0.startAt < $1.startAt }
    }

    private var items: [CalendarDisplayItem] {
        let eventItems = events.map { CalendarDisplayItem(id: "event-\($0.id)", title: $0.title, startAt: $0.startAt, endAt: $0.endAt, sourceTitle: $0.calendarTitle, color: .blue, isWorkBlock: false) }
        let blockItems = workBlocks.map { CalendarDisplayItem(id: "block-\($0.id.uuidString)", title: $0.title, startAt: $0.startAt, endAt: $0.endAt, sourceTitle: $0.projectTitle ?? $0.category.rawValue, color: $0.category.color, isWorkBlock: true) }
        return (eventItems + blockItems).sorted { $0.startAt < $1.startAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            CalendarToolbar(viewType: $viewType, title: dateTitle, moveDate: moveDate)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 10)
            if let message { Text(message).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal).padding(.bottom, 6) }
            Divider()
            ScrollView { calendarBody.padding() }
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
            case .day: CalendarDayBoard(items: items, selectedDate: selectedDate)
            case .week: CalendarWeekBoard(items: items, selectedDate: selectedDate)
            case .month: CalendarMonthBoard(items: items, selectedDate: selectedDate)
            case .year: CalendarYearBoard(items: items, selectedDate: selectedDate)
            }
        }
    }

    private var dateTitle: String {
        switch viewType {
        case .year: return selectedDate.formatted(.dateTime.year())
        case .month: return selectedDate.formatted(.dateTime.year().month(.wide))
        case .week: return "\(visibleInterval.start.formatted(date: .abbreviated, time: .omitted)) - \(visibleInterval.end.addingTimeInterval(-1).formatted(date: .abbreviated, time: .omitted))"
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
        do { selectionStore.setCalendars(try await eventKitManager.fetchCalendars()); await loadEvents() }
        catch { message = error.localizedDescription }
    }

    private func loadEvents() async {
        do { events = try await eventKitManager.fetchEvents(on: selectedDate, calendarIds: selectionStore.selectedIds, viewType: viewType); message = nil }
        catch { events = []; message = error.localizedDescription }
    }
}

struct CalendarToolbar: View {
    @Binding var viewType: BoardViewType
    let title: String
    let moveDate: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Picker("View", selection: $viewType) { ForEach(BoardViewType.allCases) { Text($0.title).tag($0) } }
                .pickerStyle(.segmented)
            HStack {
                Button { moveDate(-1) } label: { Image(systemName: "chevron.left") }.buttonStyle(.bordered)
                Spacer()
                Text(title).font(.headline).multilineTextAlignment(.center)
                Spacer()
                Button { moveDate(1) } label: { Image(systemName: "chevron.right") }.buttonStyle(.bordered)
            }
        }
    }
}

struct CalendarDayBoard: View {
    let items: [CalendarDisplayItem]
    let selectedDate: Date
    private let hourHeight: CGFloat = 64
    private var dayItems: [CalendarDisplayItem] { items.filter { Calendar.current.isDate($0.startAt, inSameDayAs: selectedDate) } }

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
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat(c.hour ?? 0) * hourHeight + CGFloat(c.minute ?? 0) / 60 * hourHeight
    }

    private func height(for item: CalendarDisplayItem) -> CGFloat {
        max(15, CGFloat(item.endAt.timeIntervalSince(item.startAt) / 3600) * hourHeight)
    }
}

struct CalendarTimedItemBlock: View {
    let item: CalendarDisplayItem
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) { Image(systemName: item.isWorkBlock ? "cube.box" : "calendar").font(.caption2); Text(item.title).font(.caption.weight(.semibold)).lineLimit(1) }
            Text("\(item.startAt.formatted(date: .omitted, time: .shortened)) - \(item.endAt.formatted(date: .omitted, time: .shortened))").font(.caption2).lineLimit(1)
            Text(item.sourceTitle).font(.caption2).lineLimit(1)
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
        let start = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }
    var body: some View { LazyVGrid(columns: columns, alignment: .leading, spacing: 8) { ForEach(weekDays, id: \.self) { CalendarDayColumn(day: $0, items: itemsForDay($0)) } } }
    private func itemsForDay(_ day: Date) -> [CalendarDisplayItem] { items.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) } }
}

struct CalendarDayColumn: View {
    let day: Date
    let items: [CalendarDisplayItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(day.formatted(.dateTime.weekday(.abbreviated))).font(.caption2).foregroundStyle(.secondary)
            Text(day.formatted(.dateTime.day())).font(.headline)
            if items.isEmpty { Text("-").font(.caption2).foregroundStyle(.secondary) }
            ForEach(items.prefix(6)) { CalendarItemChip(item: $0, compact: true) }
            if items.count > 6 { Text("+\(items.count - 6)").font(.caption2).foregroundStyle(.secondary) }
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
        guard let month = calendar.dateInterval(of: .month, for: selectedDate), let range = calendar.range(of: .day, in: .month, for: selectedDate) else { return [] }
        let first = month.start
        let leading = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        let dates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
        return Array(repeating: nil, count: leading) + dates
    }
    var body: some View {
        VStack(spacing: 6) {
            CalendarWeekdayHeader()
            LazyVGrid(columns: columns, spacing: 6) { ForEach(Array(cells.enumerated()), id: \.offset) { _, date in CalendarMonthCell(date: date, items: date.map(itemsForDay) ?? []) } }
        }
    }
    private func itemsForDay(_ day: Date) -> [CalendarDisplayItem] { items.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) } }
}

struct CalendarWeekdayHeader: View {
    private let days = Calendar.current.shortWeekdaySymbols
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    var body: some View { LazyVGrid(columns: columns, spacing: 6) { ForEach(days, id: \.self) { Text($0).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity) } } }
}

struct CalendarMonthCell: View {
    let date: Date?
    let items: [CalendarDisplayItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let date {
                Text(date.formatted(.dateTime.day())).font(.caption.weight(.semibold)).foregroundStyle(Calendar.current.isDateInToday(date) ? Color.accentColor : Color.primary)
                ForEach(items.prefix(3)) { CalendarItemChip(item: $0, compact: true) }
                if items.count > 3 { Text("+\(items.count - 3)").font(.caption2).foregroundStyle(.secondary) }
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
        let start = Calendar.current.dateInterval(of: .year, for: selectedDate)?.start ?? selectedDate
        return (0..<12).compactMap { Calendar.current.date(byAdding: .month, value: $0, to: start) }
    }
    var body: some View { LazyVGrid(columns: columns, spacing: 10) { ForEach(months, id: \.self) { CalendarYearMonthCard(month: $0, items: itemsForMonth($0)) } } }
    private func itemsForMonth(_ month: Date) -> [CalendarDisplayItem] { items.filter { Calendar.current.isDate($0.startAt, equalTo: month, toGranularity: .month) } }
}

struct CalendarYearMonthCard: View {
    let month: Date
    let items: [CalendarDisplayItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(month.formatted(.dateTime.month(.abbreviated))).font(.headline)
            Text("\(items.count) items").font(.caption).foregroundStyle(.secondary)
            ForEach(items.prefix(4)) { CalendarItemChip(item: $0, compact: true) }
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
            Text(compact ? item.title : "\(item.startAt.formatted(date: .omitted, time: .shortened)) \(item.title)").font(.caption2).lineLimit(1)
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
            Section { HStack { Button("전체 선택") { selectionStore.selectAll() }; Spacer(); Button("전체 해제") { selectionStore.clearAll() } } }
            Section("표시할 캘린더") {
                ForEach(selectionStore.calendars) { source in Toggle(source.title, isOn: Binding(get: { source.isSelected }, set: { selectionStore.toggleCalendar(source, isSelected: $0) })) }
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
                Picker("카테고리", selection: $category) { ForEach(ScheduleCategory.allCases) { Text($0.rawValue).tag($0) } }
                Text("연결 캘린더: \(selectionStore.calendarTitle(for: category))").font(.caption).foregroundStyle(.secondary)
                Button("생성") { projectStore.create(title: title, category: category, purpose: purpose, calendarIdentifier: selectionStore.calendarId(for: category)); title = ""; purpose = "" }
            }
            Section("Projects") {
                if projectStore.projects.isEmpty { Text("프로젝트가 없습니다.").foregroundStyle(.secondary) }
                ForEach(projectStore.projects) { project in NavigationLink { ProjectDetailView(project: project, projectStore: projectStore) } label: { ProjectCard(project: project, summary: projectStore.summary(for: project)) } }
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
            HStack { Text("오늘 \(summary.todayMinutes)분"); Text("완료 \(summary.completedBlocks)"); Text("중단 \(summary.stoppedBlocks)") }.font(.caption2).foregroundStyle(.secondary)
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
                ForEach(blocks) { block in WorkBlockSummaryRow(block: block) }
            }
            Section("RawTask Inbox") {
                TextField("작업", text: $taskTitle)
                TextField("메모", text: $taskMemo)
                Button("RawTask 추가") { projectStore.addRawTask(title: taskTitle, memo: taskMemo, category: project.category, projectId: project.id); taskTitle = ""; taskMemo = "" }
                ForEach(projectStore.rawTasks(for: project)) { task in RawTaskCard(task: task, project: project) }
            }
            Section("Recent Logs") {
                TextField("로그 제목", text: $logTitle)
                TextField("내용", text: $logContent, axis: .vertical)
                Stepper("집중도 \(focusLevel)", value: $focusLevel, in: 1...5)
                TextField("막힌 원인", text: $blocker)
                TextField("다음 조정", text: $nextAdjustment)
                Button("로그 작성") { projectStore.addLog(project: project, title: logTitle, content: logContent, focusLevel: focusLevel, blocker: blocker, nextAdjustment: nextAdjustment); logTitle = ""; logContent = ""; blocker = ""; nextAdjustment = ""; focusLevel = 3 }
                ForEach(projectStore.logs(for: project)) { log in LogRow(log: log, projectTitle: project.title) }
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

struct LogView: View {
    @ObservedObject var projectStore: ProjectStore
    var body: some View {
        List {
            Section("최근 로그") {
                if projectStore.logs.isEmpty { Text("작성된 로그가 없습니다.").foregroundStyle(.secondary) }
                ForEach(Array(projectStore.logs.sorted { $0.createdAt > $1.createdAt }.prefix(30))) { log in
                    LogRow(log: log, projectTitle: projectStore.project(id: log.projectId)?.title ?? "Project")
                }
            }
            Section("Closing Report Preview") {
                let todayBlocks = TimeBlockStore.loadPersistedBlocks().filter { Calendar.current.isDateInToday($0.startAt) }
                LabeledContent("완료", value: "\(todayBlocks.filter { $0.status == .completed }.count)개")
                LabeledContent("미룸", value: "\(todayBlocks.filter { $0.status == .delayed }.count)개")
                LabeledContent("중단", value: "\(todayBlocks.filter { $0.status == .stopped }.count)개")
            }
        }
        .navigationTitle("Log")
    }
}

struct LogRow: View {
    let log: ProjectLog
    let projectTitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(log.title).font(.headline)
            Text(projectTitle).font(.caption).foregroundStyle(.secondary)
            if !log.content.isEmpty { Text(log.content).foregroundStyle(.secondary) }
            if let focus = log.focusLevel { Text("집중도 \(focus)/5").font(.caption2) }
            if !log.blocker.isEmpty { Text("막힌 원인: \(log.blocker)").font(.caption2) }
            if !log.nextAdjustment.isEmpty { Text("다음 조정: \(log.nextAdjustment)").font(.caption2) }
        }
    }
}

struct ProfileView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @State private var message: String?
    var body: some View {
        List {
            Section("권한 상태") { LabeledContent("캘린더", value: eventKitManager.calendarStatusText); LabeledContent("미리알림", value: eventKitManager.remindersStatusText) }
            Section { Button("캘린더 권한 요청") { Task { await requestCalendar() } }; Button("미리알림 권한 요청") { Task { await requestReminders() } } }
            Section("시스템") { Text("서버, 로그인, 외부 API 없이 iPad 안에서 Apple Calendar/Reminders와 연결됩니다.").foregroundStyle(.secondary) }
            if let message { Text(message).foregroundStyle(.secondary) }
        }
        .navigationTitle("Profile")
    }
    private func requestCalendar() async { do { try await eventKitManager.requestCalendarAccess(); message = "캘린더 권한이 허용되었습니다." } catch { message = error.localizedDescription } }
    private func requestReminders() async { do { try await eventKitManager.requestRemindersAccess(); message = "미리알림 권한이 허용되었습니다." } catch { message = error.localizedDescription } }
}

enum AppError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let message) = self { return message }; return nil }
}
