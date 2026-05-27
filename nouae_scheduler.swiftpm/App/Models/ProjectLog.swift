import Foundation

struct ProjectLog: Identifiable, Equatable, Codable {
    let id: UUID
    var projectId: UUID
    var title: String
    var content: String
    var mood: String?
    var createdAt: Date
    var linkedWorkBlockId: UUID?

    init(id: UUID = UUID(), projectId: UUID, title: String, content: String, mood: String? = nil, createdAt: Date = Date(), linkedWorkBlockId: UUID? = nil) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.content = content
        self.mood = mood
        self.createdAt = createdAt
        self.linkedWorkBlockId = linkedWorkBlockId
    }
}
