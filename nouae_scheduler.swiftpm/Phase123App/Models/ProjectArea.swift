import Foundation
import SwiftData

@Model
final class ProjectArea {
    @Attribute(.unique) var id: UUID
    var title: String
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

extension ProjectArea {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRawValue) ?? .local }
        set { syncStateRawValue = newValue.rawValue }
    }
}
