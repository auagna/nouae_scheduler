import Foundation

struct NextAdjustment: Identifiable, Equatable, Codable {
    let id: UUID
    var projectId: UUID
    var content: String
    var createdAt: Date
    var isActive: Bool

    init(id: UUID = UUID(), projectId: UUID, content: String, createdAt: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.projectId = projectId
        self.content = content
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
