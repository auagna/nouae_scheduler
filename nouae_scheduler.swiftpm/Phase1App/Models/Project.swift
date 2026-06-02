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
    var syncStateRawValue: String = SyncState.local.rawValue
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRawValue) ?? .local }
        set { syncStateRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        type: ProjectType = .personal,
        status: ProjectStatus = .planning,
        goal: String = "",
        calendarIdentifier: String? = nil,
        calendarTitle: String? = nil,
        calendarColorHex: String? = nil,
        syncState: SyncState = .local,
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
        syncStateRawValue = syncState.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}
