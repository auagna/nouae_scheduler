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
    var executionState: WorkBlockState
    var progress: Double
    var eventIdentifier: String?
    var calendarIdentifier: String?
    var memo: String
    var createdAt: Date
    var updatedAt: Date
    var syncState: SyncState

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
        memo: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncState: SyncState = .local
    ) {
        self.id = id
        self.title = title
        self.projectId = projectId
        self.rawTaskId = rawTaskId
        self.startAt = startAt
        self.endAt = endAt
        self.executionState = executionState
        self.progress = min(max(progress, 0), 1)
        self.eventIdentifier = eventIdentifier
        self.calendarIdentifier = calendarIdentifier
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncState = syncState
    }

    var durationMinutes: Int {
        max(0, Int(endAt.timeIntervalSince(startAt) / 60))
    }
}
