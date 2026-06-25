import Foundation
import SwiftData

@Model
final class WorkBlock {
    @Attribute(.unique) var id: UUID
    var title: String
    var projectId: UUID?
    var rawTaskId: UUID?
    var startAt: Date
    var endAt: Date
    var executionStateRawValue: String
    var progress: Double
    var eventIdentifier: String?
    var calendarIdentifier: String?
    var reminderIdentifier: String?
    var reminderListIdentifier: String?
    var shouldCreateReminder: Bool
    var reminderDueAt: Date?
    var reminderNotes: String
    var memo: String
    var createdAt: Date
    var updatedAt: Date
    var syncStateRawValue: String
    var calendarSyncStateRawValue: String
    var reminderSyncStateRawValue: String

    init(
        id: UUID = UUID(),
        title: String,
        projectId: UUID? = nil,
        rawTaskId: UUID? = nil,
        startAt: Date,
        endAt: Date,
        executionState: WorkBlockState = .planned,
        progress: Double = 0,
        eventIdentifier: String? = nil,
        calendarIdentifier: String? = nil,
        reminderIdentifier: String? = nil,
        reminderListIdentifier: String? = nil,
        shouldCreateReminder: Bool = false,
        reminderDueAt: Date? = nil,
        reminderNotes: String = "",
        memo: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncState: SyncState = .local,
        calendarSyncState: SyncState? = nil,
        reminderSyncState: SyncState? = nil
    ) {
        self.id = id
        self.title = title
        self.projectId = projectId
        self.rawTaskId = rawTaskId
        self.startAt = startAt
        self.endAt = endAt
        executionStateRawValue = executionState.rawValue
        self.progress = progress
        self.eventIdentifier = eventIdentifier
        self.calendarIdentifier = calendarIdentifier
        self.reminderIdentifier = reminderIdentifier
        self.reminderListIdentifier = reminderListIdentifier
        self.shouldCreateReminder = shouldCreateReminder
        self.reminderDueAt = reminderDueAt
        self.reminderNotes = reminderNotes
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        syncStateRawValue = syncState.rawValue
        calendarSyncStateRawValue = (calendarSyncState ?? syncState).rawValue
        reminderSyncStateRawValue = (reminderSyncState ?? .local).rawValue
    }
}

extension WorkBlock {
    var executionState: WorkBlockState {
        get { WorkBlockState(rawValue: executionStateRawValue) ?? .planned }
        set { executionStateRawValue = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRawValue) ?? .local }
        set {
            syncStateRawValue = newValue.rawValue
            calendarSyncStateRawValue = newValue.rawValue
        }
    }

    var calendarSyncState: SyncState {
        get { SyncState(rawValue: calendarSyncStateRawValue) ?? syncState }
        set { calendarSyncStateRawValue = newValue.rawValue }
    }

    var reminderSyncState: SyncState {
        get { SyncState(rawValue: reminderSyncStateRawValue) ?? .local }
        set { reminderSyncStateRawValue = newValue.rawValue }
    }
}
