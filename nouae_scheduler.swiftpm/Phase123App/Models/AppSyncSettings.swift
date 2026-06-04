import Foundation
import SwiftData

@Model
final class AppSyncSettings {
    @Attribute(.unique) var id: UUID
    var blockCalendarIdentifier: String?
    var blockCalendarTitle: String
    var blockReminderListIdentifier: String?
    var blockReminderListTitle: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        blockCalendarIdentifier: String? = nil,
        blockCalendarTitle: String = "BLOCK",
        blockReminderListIdentifier: String? = nil,
        blockReminderListTitle: String = "BLOCK",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.blockCalendarIdentifier = blockCalendarIdentifier
        self.blockCalendarTitle = blockCalendarTitle
        self.blockReminderListIdentifier = blockReminderListIdentifier
        self.blockReminderListTitle = blockReminderListTitle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
