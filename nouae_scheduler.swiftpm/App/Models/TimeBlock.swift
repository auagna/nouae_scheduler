import Foundation

struct TimeBlock: Identifiable, Equatable {
    let id: UUID
    var title: String
    var category: ScheduleCategory
    var startAt: Date
    var endAt: Date
    var calendarIdentifier: String?
    var eventIdentifier: String?
    var syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        title: String,
        category: ScheduleCategory,
        startAt: Date,
        endAt: Date,
        calendarIdentifier: String? = nil,
        eventIdentifier: String? = nil,
        syncStatus: SyncStatus = .local
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startAt = startAt
        self.endAt = endAt
        self.calendarIdentifier = calendarIdentifier
        self.eventIdentifier = eventIdentifier
        self.syncStatus = syncStatus
    }

    var durationMinutes: Int {
        max(15, Int(endAt.timeIntervalSince(startAt) / 60))
    }
}
