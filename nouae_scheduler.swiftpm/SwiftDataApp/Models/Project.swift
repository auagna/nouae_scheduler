import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var title: String
    var type: ProjectType
    var status: ProjectStatus
    var goal: String
    var calendarIdentifier: String?
    var calendarTitle: String?
    var calendarColorHex: String?
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        type: ProjectType = .personal,
        status: ProjectStatus = .planning,
        goal: String = "",
        calendarIdentifier: String? = nil,
        calendarTitle: String? = nil,
        calendarColorHex: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.status = status
        self.goal = goal
        self.calendarIdentifier = calendarIdentifier
        self.calendarTitle = calendarTitle
        self.calendarColorHex = calendarColorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }

    var isArchived: Bool {
        status == .archived || archivedAt != nil
    }
}
