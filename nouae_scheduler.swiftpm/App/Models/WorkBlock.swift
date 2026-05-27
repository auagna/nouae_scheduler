import Foundation

struct WorkBlock: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var startAt: Date
    var endAt: Date
    var category: ScheduleCategory
    var projectId: UUID?
    var projectTitle: String?
    var rawTaskId: UUID?
    var calendarIdentifier: String?
    var eventIdentifier: String?
    var syncStatus: SyncStatus

    init(id: UUID = UUID(), title: String, startAt: Date, endAt: Date, category: ScheduleCategory, projectId: UUID? = nil, projectTitle: String? = nil, rawTaskId: UUID? = nil, calendarIdentifier: String? = nil, eventIdentifier: String? = nil, syncStatus: SyncStatus = .local) {
        self.id = id
        self.title = title
        self.startAt = startAt
        self.endAt = endAt
        self.category = category
        self.projectId = projectId
        self.projectTitle = projectTitle
        self.rawTaskId = rawTaskId
        self.calendarIdentifier = calendarIdentifier
        self.eventIdentifier = eventIdentifier
        self.syncStatus = syncStatus
    }

    var durationMinutes: Int {
        max(15, Int(endAt.timeIntervalSince(startAt) / 60))
    }
}

typealias TimeBlock = WorkBlock
