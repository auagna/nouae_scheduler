import Foundation
import SwiftUI

struct CalendarTimelineItem: Identifiable, Equatable {
    var id: String
    var title: String
    var startAt: Date
    var endAt: Date
    var calendarIdentifier: String?
    var colorHex: String?
    var projectId: UUID?
    var workBlockId: UUID?
    var externalEventIdentifier: String?
    var isLocalOnly: Bool

    static func local(block: WorkBlock, project: Project?) -> CalendarTimelineItem {
        CalendarTimelineItem(
            id: "block-\(block.id.uuidString)",
            title: block.title,
            startAt: block.startAt,
            endAt: block.endAt,
            calendarIdentifier: block.calendarIdentifier ?? project?.calendarIdentifier,
            colorHex: project?.calendarColorHex,
            projectId: block.projectId,
            workBlockId: block.id,
            externalEventIdentifier: block.eventIdentifier,
            isLocalOnly: block.eventIdentifier == nil
        )
    }
}

enum DateSnapper {
    static let snapMinutes = 10
    static let minimumDurationMinutes = 10

    static func minuteOfDay(for date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    static func date(on day: Date, minuteOfDay: Int, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: day)
        let minute = max(0, min(minuteOfDay, 24 * 60 - snapMinutes))
        return calendar.date(byAdding: .minute, value: minute, to: start) ?? start
    }

    static func snappedDate(_ date: Date, calendar: Calendar = .current) -> Date {
        let minute = minuteOfDay(for: date, calendar: calendar)
        let snapped = Int((Double(minute) / Double(snapMinutes)).rounded()) * snapMinutes
        return self.date(on: date, minuteOfDay: snapped, calendar: calendar)
    }

    static func normalizedRange(startAt: Date, endAt: Date, calendar: Calendar = .current) -> (startAt: Date, endAt: Date) {
        let snappedStart = snappedDate(startAt, calendar: calendar)
        let snappedEnd = snappedDate(endAt, calendar: calendar)
        if snappedEnd.timeIntervalSince(snappedStart) >= Double(minimumDurationMinutes * 60) {
            return (snappedStart, snappedEnd)
        }
        let fallbackEnd = calendar.date(byAdding: .minute, value: minimumDurationMinutes, to: snappedStart) ?? snappedStart
        return (snappedStart, fallbackEnd)
    }
}

extension Color {
    init(calendarHex hex: String?) {
        guard let hex else {
            self = .accentColor
            return
        }
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let number = Int(value, radix: 16) else {
            self = .accentColor
            return
        }
        let red = Double((number >> 16) & 0xFF) / 255.0
        let green = Double((number >> 8) & 0xFF) / 255.0
        let blue = Double(number & 0xFF) / 255.0
        self = Color(red: red, green: green, blue: blue)
    }
}
