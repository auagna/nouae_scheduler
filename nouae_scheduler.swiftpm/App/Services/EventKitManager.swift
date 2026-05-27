import EventKit
import Foundation
import UIKit

@MainActor
final class EventKitManager: ObservableObject {
    @Published private(set) var calendarStatusText = "확인 필요"
    @Published private(set) var remindersStatusText = "확인 필요"

    private let eventStore = EKEventStore()

    init() { refreshAuthorizationStatus() }

    func refreshAuthorizationStatus() {
        calendarStatusText = statusText(for: EKEventStore.authorizationStatus(for: .event))
        remindersStatusText = statusText(for: EKEventStore.authorizationStatus(for: .reminder))
    }

    func requestCalendarAccessIfNeeded() async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        if isGranted(status) { return }
        if status == .notDetermined {
            try await requestCalendarAccess()
            return
        }
        refreshAuthorizationStatus()
        throw EventKitManagerError.accessDenied("캘린더 권한이 없습니다. Settings에서 권한을 허용해 주세요.")
    }

    func requestCalendarAccess() async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        refreshAuthorizationStatus()
        if !granted { throw EventKitManagerError.accessDenied("캘린더 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.") }
    }

    func requestRemindersAccess() async throws {
        let granted = try await eventStore.requestFullAccessToReminders()
        refreshAuthorizationStatus()
        if !granted { throw EventKitManagerError.accessDenied("미리알림 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.") }
    }

    func fetchCalendars() async throws -> [CalendarSource] {
        try await requestCalendarAccessIfNeeded()
        return eventStore.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { CalendarSource(id: $0.calendarIdentifier, title: $0.title, colorHex: hexString(from: $0.cgColor), isSelected: true) }
    }

    func createCalendar(title: String, category: ScheduleCategory) async throws -> CalendarSource? {
        try await requestCalendarAccessIfNeeded()
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return nil }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = cleanTitle
        calendar.cgColor = uiColor(for: category).cgColor

        if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
            calendar.source = defaultSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = localSource
        } else if let firstSource = eventStore.sources.first {
            calendar.source = firstSource
        } else {
            throw EventKitManagerError.unavailable("새 캘린더를 만들 수 있는 Calendar source를 찾지 못했습니다.")
        }

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return CalendarSource(id: calendar.calendarIdentifier, title: calendar.title, colorHex: hexString(from: calendar.cgColor), isSelected: true)
        } catch {
            throw EventKitManagerError.saveFailed("캘린더 생성에 실패했습니다: \(error.localizedDescription)")
        }
    }

    func updateEventCalendarIfNeeded(eventIdentifier: String, calendarIdentifier: String) async throws {
        try await requestCalendarAccessIfNeeded()
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else { return }
        guard event.calendar.calendarIdentifier != calendarIdentifier else { return }
        guard let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) else {
            throw EventKitManagerError.unavailable("연결된 캘린더를 찾을 수 없습니다.")
        }
        event.calendar = calendar
        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    func fetchEvents(from startDate: Date, to endDate: Date, calendarIds: [String]) async throws -> [CalendarEvent] {
        try await requestCalendarAccessIfNeeded()
        guard !calendarIds.isEmpty else { return [] }
        let calendars = eventStore.calendars(for: .event).filter { calendarIds.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                CalendarEvent(
                    id: event.eventIdentifier ?? event.calendarItemIdentifier,
                    title: event.title,
                    startAt: event.startDate,
                    endAt: event.endDate,
                    calendarId: event.calendar.calendarIdentifier,
                    calendarTitle: event.calendar.title,
                    colorHex: hexString(from: event.calendar.cgColor),
                    notes: event.notes
                )
            }
    }

    func createReminder(title: String, dueDate: Date, category: ScheduleCategory) async throws {
        try ensureReminderAccess()
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw EventKitManagerError.validation("할 일 제목을 입력해 주세요.") }
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw EventKitManagerError.unavailable("기본 미리알림 목록을 찾을 수 없습니다.")
        }
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = cleanTitle
        reminder.calendar = calendar
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        do { try eventStore.save(reminder, commit: true) } catch {
            throw EventKitManagerError.saveFailed("미리알림 저장에 실패했습니다: \(error.localizedDescription)")
        }
    }

    func saveTimeBlock(_ block: TimeBlock) async throws -> TimeBlock {
        try ensureCalendarAccess()
        let cleanTitle = block.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw EventKitManagerError.validation("일정 제목을 입력해 주세요.") }
        guard block.endAt > block.startAt else { throw EventKitManagerError.validation("종료 시간은 시작 시간보다 늦어야 합니다.") }
        guard let calendarIdentifier = block.calendarIdentifier,
              let targetCalendar = eventStore.calendar(withIdentifier: calendarIdentifier) else {
            throw EventKitManagerError.validation("\(block.category.rawValue) 카테고리에 연결된 Apple Calendar가 없습니다.")
        }

        let event: EKEvent
        if let eventIdentifier = block.eventIdentifier,
           let existingEvent = eventStore.event(withIdentifier: eventIdentifier) {
            event = existingEvent
        } else {
            event = EKEvent(eventStore: eventStore)
        }

        event.calendar = targetCalendar
        event.title = cleanTitle
        event.startDate = block.startAt
        event.endDate = block.endAt
        event.notes = eventNotes(for: block)

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            var savedBlock = block
            savedBlock.calendarIdentifier = event.calendar.calendarIdentifier
            savedBlock.eventIdentifier = event.eventIdentifier
            savedBlock.syncStatus = .synced
            return savedBlock
        } catch {
            throw EventKitManagerError.saveFailed("일정 저장에 실패했습니다: \(error.localizedDescription)")
        }
    }

    func fetchTodaySchedules() async throws -> [EKEvent] {
        try ensureCalendarAccess()
        let dayStart = Calendar.current.startOfDay(for: Date())
        return fetchEKEvents(from: dayStart, days: 1)
    }

    func fetchTodayTimeBlocks() async throws -> [TimeBlock] {
        try ensureCalendarAccess()
        let dayStart = Calendar.current.startOfDay(for: Date())
        return fetchEKEvents(from: dayStart, days: 1).map { event in
            let metadata = metadata(from: event.notes)
            return TimeBlock(
                title: event.title,
                category: metadata.category ?? .work,
                startAt: event.startDate,
                endAt: event.endDate,
                calendarIdentifier: event.calendar.calendarIdentifier,
                eventIdentifier: event.eventIdentifier,
                syncStatus: .synced,
                projectId: metadata.projectId,
                projectTitle: metadata.projectTitle
            )
        }
    }

    func fetchTodayReminders() async throws -> [EKReminder] {
        try ensureReminderAccess()
        let predicate = eventStore.predicateForReminders(in: nil)
        let reminders = await fetchReminders(matching: predicate)
        let calendar = Calendar.current
        return reminders
            .filter { reminder in
                guard !reminder.isCompleted,
                      let components = reminder.dueDateComponents,
                      let dueDate = calendar.date(from: components) else { return false }
                return calendar.isDateInToday(dueDate)
            }
            .sorted { first, second in
                let firstDate = first.dueDateComponents.flatMap { calendar.date(from: $0) } ?? .distantFuture
                let secondDate = second.dueDateComponents.flatMap { calendar.date(from: $0) } ?? .distantFuture
                return firstDate < secondDate
            }
    }

    private func fetchEKEvents(from start: Date, days: Int) -> [EKEvent] {
        guard let end = Calendar.current.date(byAdding: .day, value: days, to: start) else { return [] }
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    private func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
        await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in continuation.resume(returning: reminders ?? []) }
        }
    }

    private func ensureCalendarAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        if !isGranted(status) { throw EventKitManagerError.accessDenied("캘린더 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.") }
    }

    private func ensureReminderAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if !isGranted(status) { throw EventKitManagerError.accessDenied("미리알림 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.") }
    }

    private func isGranted(_ status: EKAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .fullAccess: return true
        case .writeOnly, .notDetermined, .restricted, .denied: return false
        @unknown default: return false
        }
    }

    private func statusText(for status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "아직 요청하지 않음"
        case .restricted: return "제한됨"
        case .denied: return "거부됨"
        case .authorized: return "허용됨"
        case .fullAccess: return "전체 접근 허용"
        case .writeOnly: return "쓰기 전용"
        @unknown default: return "알 수 없음"
        }
    }

    private func eventNotes(for block: TimeBlock) -> String {
        var lines = ["nouae category: \(block.category.rawValue)"]
        if let projectId = block.projectId { lines.append("nouae projectId: \(projectId.uuidString)") }
        if let projectTitle = block.projectTitle { lines.append("nouae projectTitle: \(projectTitle)") }
        return lines.joined(separator: "\n")
    }

    private func metadata(from notes: String?) -> (category: ScheduleCategory?, projectId: UUID?, projectTitle: String?) {
        guard let notes else { return (nil, nil, nil) }
        var category: ScheduleCategory?
        var projectId: UUID?
        var projectTitle: String?
        for line in notes.components(separatedBy: .newlines) {
            if line.hasPrefix("nouae category: ") {
                category = ScheduleCategory(rawValue: String(line.dropFirst("nouae category: ".count)))
            } else if line.hasPrefix("nouae projectId: ") {
                projectId = UUID(uuidString: String(line.dropFirst("nouae projectId: ".count)))
            } else if line.hasPrefix("nouae projectTitle: ") {
                projectTitle = String(line.dropFirst("nouae projectTitle: ".count))
            }
        }
        return (category, projectId, projectTitle)
    }

    private func hexString(from cgColor: CGColor) -> String? {
        let color = UIColor(cgColor: cgColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }

    private func uiColor(for category: ScheduleCategory) -> UIColor {
        switch category {
        case .work: return .systemBlue
        case .company: return .systemPurple
        case .personal: return .systemGreen
        case .social: return .systemOrange
        }
    }
}

enum EventKitManagerError: LocalizedError {
    case accessDenied(String)
    case validation(String)
    case unavailable(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied(let message), .validation(let message), .unavailable(let message), .saveFailed(let message): return message
        }
    }
}
