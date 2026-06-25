import Foundation
import SwiftData

@Model
final class ProjectMemoSection {
    @Attribute(.unique) var id: UUID = UUID()
    var projectId: UUID = UUID()
    var sectionTypeRawValue: String = ProjectSectionType.memo.rawValue
    var title: String = ""
    var content: String = ""
    var order: Int = 0
    var isGenerated: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        projectId: UUID,
        sectionType: ProjectSectionType = .memo,
        title: String,
        content: String = "",
        order: Int = 0,
        isGenerated: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        sectionTypeRawValue = sectionType.rawValue
        self.title = title
        self.content = content
        self.order = order
        self.isGenerated = isGenerated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension ProjectMemoSection {
    var sectionType: ProjectSectionType {
        get { ProjectSectionType(rawValue: sectionTypeRawValue) ?? .memo }
        set { sectionTypeRawValue = newValue.rawValue }
    }
}