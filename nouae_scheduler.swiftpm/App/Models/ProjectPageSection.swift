import Foundation

struct ProjectPageSection: Identifiable, Equatable, Codable {
    let id: UUID
    var projectId: UUID
    var title: String
    var content: String
    var order: Int
    var isGenerated: Bool
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), projectId: UUID, title: String, content: String, order: Int, isGenerated: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.content = content
        self.order = order
        self.isGenerated = isGenerated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
