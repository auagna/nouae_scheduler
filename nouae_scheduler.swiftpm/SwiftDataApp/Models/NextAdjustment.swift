import Foundation
import SwiftData

@Model
final class NextAdjustment {
    @Attribute(.unique) var id: UUID
    var projectId: UUID?
    var content: String
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID? = nil,
        content: String,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.content = content
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
