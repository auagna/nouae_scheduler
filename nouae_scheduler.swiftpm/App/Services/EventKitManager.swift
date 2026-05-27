import EventKit
import Foundation
import UIKit

@MainActor
final class EventKitManager: ObservableObject {
    @Published private(set) var calendarStatusText = "확인 필요"
    @Published private(set) var remindersStatusText = "확인 필요"

    private let eventStore = EKEventStore()

    init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        calendarStatusText = statusText(for: EKEventStore.authorizationStatus(for: .event))
        remindersStatusText = statusText(for: EKEventStore.authorizationStatus(for: .reminder))
    }

    func requestCalendarAccessIfNeeded() async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        if isGranted(status) {
            return
        }

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

        if !granted {
            throw EventKitManagerError.accessDenied("캘린더 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.")
        }
    }

    func requestRemindersAccess() async throws {
        let granted = try await eventStore.requestFullAccessToReminders()
        refreshAuthorizationStatus()

        if !granted {
            throw EventKitManagerError.accessDenied("미리알림 접근 권한이 필요합니다. iPad 설정 앱에서 권한을 허용해 주세요.")
        }
    }

    func fetchCalendars() async throws -> [CalendarSource] {
        try await requestCalendarAccessIfNeeded()

        return eventStore.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { calendar in
                CalendarSource(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    colorHex: hexString(from: calendar.cgColor),
                    isSelected: true
                )
            }
    }

    func fetchEvents(from startDate: Date, to endDate: Date, calendarIds: [String]) async throws -> [CalendarEvent] {
        try await requestCalendarAccessIfNeeded()

        guard !calendarIds.isEmpty else {
            return []
        }

        let calendars = eventStore.calendars(for: .event).filter { calendarIds.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else {
            return []
        }

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

        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw EventKitManagerError.validation("할 일 제목을 입력해 주세요.")
        }

        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw EventKitManagerError.unavailable("기본 미리알림 목록을 찾을 수 없습니다.")
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = "[\(category.rawValue)] \(title)"
        reminder.calendar = calendar
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)

        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            throw EventKitManagerError.saveFailed("미리알림 저장에 실패했습니다: \(error.localizedDescription)")
        }
    }

    func saveTimeBlock(_ block: TimeBlock) async throws -> TimeBlock {
        try ensureCalendarAccess()

        guard !block.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw EventKitManagerError.validation("일정 제목을 입력해 주세요.")
        }

        guard block.endAt > block.startAt else {
            throw EventKitManagerError.validation("종료 시간은 시작 시간보다 늦어야 합니다.")
        }

        let event: EKEvent
        if let eventIdentifier = block.eventIdentifier,
           let existingEvent = eventStore.event(withIdentifier: eventIdentifier) {
            event = existingEvent
        } else {
            event = EKEvent(eventStore: eventStore)
            guard let calendar = eventStore.defaultCalendarForNewEvents else {
                throw EventKitManagerError.unavailable("기본 캘린더를 찾을 수 없습니다.")
            }
            event.calendar = calendar
        }

        event.title = "[\(block.category.rawValue)] \(block.title)"
        event.startDate = block.startAt
        event.endDate = block.endAt
        event.notes = "nouae category: \(block.category.rawValue)"

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
            TimeBlock(
                title: cleanTitle(event.title),
                category: category(from: event.title),
                startAt: event.startDate,
                endAt: event.endDate,
                calendarIdentifier: event.calendar.calendarIdentifier,
                eventIdentifier: event.eventIdentifier,
                syncStatus: .synced
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
                      let dueDate = calendar.date(from: components) else {
                    return false
                }
                return calendar.isDateInToday(dueDate)
            }
            .sorted { first, second in
                let firstDate = first.dueDateComponents.flatMap { calendar.date(from: $0) } ?? .distantFuture
                let secondDate = second.dueDateComponents.flatMap { calendar.date(from: $0) } ?? .distantFuture
                return firstDate < secondDate
            }
    }

    private func fetchEKEvents(from start: Date, days: Int) -> [EKEvent] {
        guard let end = Calendar.current.date(byAdding: .day, value: days, to: start) else {
            return []
        }
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    private func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
        await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private func ensureCalendarAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        if !isGranted(status) {
            throw EventKitManagerError.accessDenied("캘린더 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.")
        }
    }

    private func ensureReminderAccess() throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if !isGranted(status) {
            throw EventKitManagerError.accessDenied("미리알림 권한이 없습니다. Settings 탭에서 권한을 요청해 주세요.")
        }
    }

    private func isGranted(_ status: EKAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .fullAccess:
            return true
        case .writeOnly, .notDetermined, .restricted, .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func statusText(for status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "아직 요청하지 않음"
        case .restricted:
            return "제한됨"
        case .denied:
            return "거부됨"
        case .authorized:
            return "허용됨"
        case .fullAccess:
            return "전체 접근 허용"
        case .writeOnly:
            return "쓰기 전용"
        @unknown default:
            return "알 수 없음"
        }
    }

    private func category(from title: String) -> ScheduleCategory {
        for category in ScheduleCategory.allCases where title.hasPrefix("[\(category.rawValue)]") {
            return category
        }
        return .work
    }

    private func cleanTitle(_ title: String) -> String {
        for category in ScheduleCategory.allCases {
            let prefix = "[\(category.rawValue)] "
            if title.hasPrefix(prefix) {
                return String(title.dropFirst(prefix.count))
            }
        }
        return title
    }

    private func hexString(from cgColor: CGColor) -> String? {
        let color = UIColor(cgColor: cgColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

enum EventKitManagerError: LocalizedError {
    case accessDenied(String)
    case validation(String)
    case unavailable(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied(let message),
             .validation(let message),
             .unavailable(let message),
             .saveFailed(let message):
            return message
        }
    }
}
