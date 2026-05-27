import Foundation

struct Project: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var category: ScheduleCategory
    var note: String?
    var calendarIdentifier: String?
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        title: String,
        category: ScheduleCategory,
        note: String? = nil,
        calendarIdentifier: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.note = note
        self.calendarIdentifier = calendarIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}
