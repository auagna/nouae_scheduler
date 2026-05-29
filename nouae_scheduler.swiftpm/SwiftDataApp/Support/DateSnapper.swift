import Foundation

enum DateSnapper {
    static func snapToTenMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let totalMinutes = hour * 60 + minute
        let snappedTotal = Int((Double(totalMinutes) / 10.0).rounded()) * 10
        let clamped = min(max(snappedTotal, 0), 23 * 60 + 50)
        return calendar.date(
            bySettingHour: clamped / 60,
            minute: clamped % 60,
            second: 0,
            of: date
        ) ?? date
    }

    static func dayInterval(for date: Date) -> DateInterval {
        Calendar.current.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 24 * 60 * 60)
    }

    static func weekInterval(for date: Date) -> DateInterval {
        Calendar.current.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 24 * 60 * 60)
    }
}
