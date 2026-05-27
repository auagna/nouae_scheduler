import Foundation

struct TimeBlock: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var category: ScheduleCategory
    var startAt: Date
    var endAt: Date
    var calendarIdentifier: String?
    var eventIdentifier: String?
    var syncStatus: SyncStatus
    var projectId: UUID?
    var projectTitle: String?

    init(
        id: UUID = UUID(),
        title: String,
        category: ScheduleCategory,
        startAt: Date,
        endAt: Date,
        calendarIdentifier: String? = nil,
        eventIdentifier: String? = nil,
        syncStatus: SyncStatus = .local,
        projectId: UUID? = nil,
        projectTitle: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startAt = startAt
        self.endAt = endAt
        self.calendarIdentifier = calendarIdentifier
        self.eventIdentifier = eventIdentifier
        self.syncStatus = syncStatus
        self.projectId = projectId
        self.projectTitle = projectTitle
    }

    var durationMinutes: Int {
        max(15, Int(endAt.timeIntervalSince(startAt) / 60))
    }
}
