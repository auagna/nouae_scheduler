import Foundation
import SwiftData

@Model
final class ProjectMemoSection {
    @Attribute(.unique) var id: UUID
    var projectId: UUID
    var title: String
    var content: String
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), projectId: UUID, title: String, content: String = "", order: Int, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.content = content
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
