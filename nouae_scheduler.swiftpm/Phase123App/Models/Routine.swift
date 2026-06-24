import Foundation

enum RoutineFrequency: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekdays
    case weekly
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekly: return "Weekly"
        case .custom: return "Custom"
        }
    }
}

enum RoutineOccurrenceState: String, CaseIterable, Identifiable, Codable {
    case pending
    case placed
    case skipped
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "Pending"
        case .placed: return "Placed"
        case .skipped: return "Skipped"
        case .completed: return "Completed"
        }
    }
}

enum RoutineWeekday: Int, CaseIterable, Identifiable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortTitle: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var maskValue: Int {
        1 << rawValue
    }

    static var everyDayMask: Int {
        allCases.reduce(0) { $0 | $1.maskValue }
    }

    static var weekdaysMask: Int {
        [monday, tuesday, wednesday, thursday, friday].reduce(0) { $0 | $1.maskValue }
    }
}

struct Routine: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var areaId: UUID?
    var projectId: UUID?
    var frequency: RoutineFrequency = .daily
    var weekdayMask: Int = RoutineWeekday.everyDayMask
    var startMinuteOfDay: Int = 9 * 60
    var durationMinutes: Int = 60
    var notes: String = ""
    var isActive: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var archivedAt: Date?

    var isArchived: Bool {
        archivedAt != nil
    }

    func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        guard isActive, !isArchived else { return false }
        let weekday = calendar.component(.weekday, from: date)
        return weekdayMask & (1 << weekday) != 0
    }
}

struct RoutineOccurrence: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var routineId: UUID
    var areaId: UUID?
    var projectId: UUID?
    var title: String
    var occurrenceDate: Date
    var plannedStartAt: Date
    var plannedEndAt: Date
    var workBlockId: UUID?
    var state: RoutineOccurrenceState = .pending
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
