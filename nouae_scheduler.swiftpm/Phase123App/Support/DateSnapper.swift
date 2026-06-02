import Foundation

enum DateSnapper {
    static let intervalMinutes = 10
    static let minimumDurationMinutes = 10

    static func snap(_ date: Date) -> Date {
        let start = Calendar.current.startOfDay(for: date)
        let seconds = date.timeIntervalSince(start)
        let interval = TimeInterval(intervalMinutes * 60)
        return start.addingTimeInterval((seconds / interval).rounded() * interval)
    }

    static func date(on day: Date, minuteOfDay: Int) -> Date {
        Calendar.current.startOfDay(for: day).addingTimeInterval(TimeInterval(clampMinute(minuteOfDay) * 60))
    }

    static func minuteOfDay(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    static func snappedMinuteDelta(for translation: CGFloat, pointsPerMinute: CGFloat) -> Int {
        guard pointsPerMinute > 0 else { return 0 }
        return Int((translation / pointsPerMinute / CGFloat(intervalMinutes)).rounded()) * intervalMinutes
    }

    static func normalizedRange(startAt: Date, endAt: Date) -> (startAt: Date, endAt: Date) {
        let start = snap(startAt)
        let snappedEnd = snap(endAt)
        let minimumEnd = Calendar.current.date(byAdding: .minute, value: minimumDurationMinutes, to: start) ?? start
        return (start, max(snappedEnd, minimumEnd))
    }

    static func clampMinute(_ minute: Int) -> Int {
        min(max(0, minute), 23 * 60 + 50)
    }
}
