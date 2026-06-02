import Foundation
import SwiftData

@Model
final class ProjectLog {
    @Attribute(.unique) var id: UUID
    var projectId: UUID?
    var workBlockId: UUID?
    var focusLevel: Int?
    var blockerTags: [String]
    var blockerNote: String
    var nextAdjustment: String
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), projectId: UUID? = nil, workBlockId: UUID? = nil, focusLevel: Int? = nil, blockerTags: [String] = [], blockerNote: String = "", nextAdjustment: String = "", content: String = "", createdAt: Date = Date()) {
        self.id = id
        self.projectId = projectId
        self.workBlockId = workBlockId
        self.focusLevel = focusLevel
        self.blockerTags = blockerTags
        self.blockerNote = blockerNote
        self.nextAdjustment = nextAdjustment
        self.content = content
        self.createdAt = createdAt
    }
}
