import Foundation
import SwiftData

@MainActor
final class ProjectBoardStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createItem(
        projectId: UUID,
        type: ProjectBoardItemType,
        title: String,
        content: String,
        url: String = "",
        colorHex: String? = nil
    ) throws -> ProjectBoardItem {
        let order = try items(projectId: projectId).count
        let item = ProjectBoardItem(
            projectId: projectId,
            itemType: type,
            title: title,
            content: content,
            url: url,
            colorHex: colorHex,
            order: order
        )
        context.insert(item)
        try context.save()
        return item
    }

    func items(projectId: UUID) throws -> [ProjectBoardItem] {
        try context.fetch(FetchDescriptor<ProjectBoardItem>(sortBy: [SortDescriptor(\.order), SortDescriptor(\.updatedAt, order: .reverse)]))
            .filter { $0.projectId == projectId && !$0.isArchived }
    }

    func update(item: ProjectBoardItem, title: String, content: String, url: String, colorHex: String?) throws {
        item.title = title
        item.content = content
        item.url = url
        item.colorHex = colorHex
        item.updatedAt = Date()
        try context.save()
    }

    func archive(item: ProjectBoardItem) throws {
        item.archivedAt = Date()
        item.updatedAt = Date()
        try context.save()
    }
}
