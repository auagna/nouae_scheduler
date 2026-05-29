import Foundation
import SwiftData

@Model
final class RawTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var projectId: UUID?
    var reminderIdentifier: String?
    var createdAt: Date
    var scheduledAt: Date?
    var isConvertedToBlock: Bool
    var syncState: SyncState

    init(
        id: UUID = UUID(),
        title: String,
        projectId: UUID? = nil,
        reminderIdentifier: String? = nil,
        createdAt: Date = Date(),
        scheduledAt: Date? = nil,
        isConvertedToBlock: Bool = false,
        syncState: SyncState = .local
    ) {
        self.id = id
        self.title = title
        self.projectId = projectId
        self.reminderIdentifier = reminderIdentifier
        self.createdAt = createdAt
        self.scheduledAt = scheduledAt
        self.isConvertedToBlock = isConvertedToBlock
        self.syncState = syncState
    }
}
