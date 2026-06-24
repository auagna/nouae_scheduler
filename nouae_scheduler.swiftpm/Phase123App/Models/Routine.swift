import Foundation
import SwiftData

enum RoutineFrequency: String, CaseIterable, Identifiable {
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

enum RoutineOccurrenceState: String, CaseIterable, Identifiable {
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

enum RoutineWeekday: Int, CaseIterable, Identifiable {
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

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var title: String
    var areaId: UUID?
    var projectId: UUID?
    var frequencyRawValue: String
    var weekdayMask: Int
    var startMinuteOfDay: Int
    var durationMinutes: Int
    var notes: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        frequency: RoutineFrequency = .daily,
        weekdayMask: Int = RoutineWeekday.everyDayMask,
        startMinuteOfDay: Int = 9 * 60,
        durationMinutes: Int = 60,
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.areaId = areaId
        self.projectId = projectId
        frequencyRawValue = frequency.rawValue
        self.weekdayMask = weekdayMask
        self.startMinuteOfDay = startMinuteOfDay
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

extension Routine {
    var frequency: RoutineFrequency {
        get { RoutineFrequency(rawValue: frequencyRawValue) ?? .daily }
        set { frequencyRawValue = newValue.rawValue }
    }

    var isArchived: Bool {
        archivedAt != nil
    }

    func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        guard isActive, !isArchived else { return false }
        let weekday = calendar.component(.weekday, from: date)
        return weekdayMask & (1 << weekday) != 0
    }
}

@Model
final class RoutineOccurrence {
    @Attribute(.unique) var id: UUID
    var routineId: UUID
    var areaId: UUID?
    var projectId: UUID?
    var title: String
    var occurrenceDate: Date
    var plannedStartAt: Date
    var plannedEndAt: Date
    var workBlockId: UUID?
    var stateRawValue: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        routineId: UUID,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        title: String,
        occurrenceDate: Date,
        plannedStartAt: Date,
        plannedEndAt: Date,
        workBlockId: UUID? = nil,
        state: RoutineOccurrenceState = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.routineId = routineId
        self.areaId = areaId
        self.projectId = projectId
        self.title = title
        self.occurrenceDate = occurrenceDate
        self.plannedStartAt = plannedStartAt
        self.plannedEndAt = plannedEndAt
        self.workBlockId = workBlockId
        stateRawValue = state.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension RoutineOccurrence {
    var state: RoutineOccurrenceState {
        get { RoutineOccurrenceState(rawValue: stateRawValue) ?? .pending }
        set { stateRawValue = newValue.rawValue }
    }
}
