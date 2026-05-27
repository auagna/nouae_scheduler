import Foundation

struct CalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startAt: Date
    let endAt: Date
    let calendarId: String
    let calendarTitle: String
    let colorHex: String?
    let notes: String?
}
