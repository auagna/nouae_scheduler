import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var title: String
    var typeRawValue: String
    var statusRawValue: String
    var goal: String
    var areaId: UUID?
    var calendarIdentifier: String?
    var calendarTitle: String?
    var calendarColorHex: String?
    var reminderListIdentifier: String?
    var reminderListTitle: String?
    var syncStateRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        type: ProjectType = .personal,
        status: ProjectStatus = .planning,
        goal: String = "",
        areaId: UUID? = nil,
        calendarIdentifier: String? = nil,
        calendarTitle: String? = nil,
        calendarColorHex: String? = nil,
        reminderListIdentifier: String? = nil,
        reminderListTitle: String? = nil,
        syncState: SyncState = .local,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        typeRawValue = type.rawValue
        statusRawValue = status.rawValue
        self.goal = goal
        self.areaId = areaId
        self.calendarIdentifier = calendarIdentifier
        self.calendarTitle = calendarTitle
        self.calendarColorHex = calendarColorHex
        self.reminderListIdentifier = reminderListIdentifier
        self.reminderListTitle = reminderListTitle
        syncStateRawValue = syncState.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

extension Project {
    var type: ProjectType {
        get { ProjectType(rawValue: typeRawValue) ?? .personal }
        set { typeRawValue = newValue.rawValue }
    }

    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRawValue) ?? .planning }
        set { statusRawValue = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRawValue) ?? .local }
        set { syncStateRawValue = newValue.rawValue }
    }
}
