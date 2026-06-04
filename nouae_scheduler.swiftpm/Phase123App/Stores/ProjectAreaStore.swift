import Foundation
import SwiftData

@MainActor
final class ProjectAreaStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAreas(includeArchived: Bool = false) throws -> [ProjectArea] {
        try context.fetch(FetchDescriptor<ProjectArea>())
            .filter { includeArchived || $0.archivedAt == nil }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func findArea(id: UUID?) throws -> ProjectArea? {
        guard let id else { return nil }
        return try context.fetch(FetchDescriptor<ProjectArea>()).first { $0.id == id }
    }

    func createLocalArea(title: String) throws -> ProjectArea {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw SyncError.invalidTitle }
        try validateUniqueActiveTitle(trimmedTitle)
        let area = ProjectArea(title: trimmedTitle)
        context.insert(area)
        try context.save()
        return area
    }

    func ensureUnassignedArea() throws -> ProjectArea {
        if let existing = try context.fetch(FetchDescriptor<ProjectArea>()).first(where: { $0.title == "Unassigned" && $0.archivedAt == nil }) {
            return existing
        }
        let area = ProjectArea(title: "Unassigned")
        context.insert(area)
        try context.save()
        return area
    }

    func assign(project: Project, to area: ProjectArea?) throws {
        project.areaId = area?.id
        project.updatedAt = Date()

        // Temporary compatibility until WorkBlock routing resolves Area directly.
        project.calendarIdentifier = area?.calendarIdentifier
        project.calendarTitle = area?.calendarTitle
        project.calendarColorHex = area?.calendarColorHex

        try context.save()
    }

    func archiveArea(_ area: ProjectArea) throws {
        area.archivedAt = Date()
        area.updatedAt = Date()
        try context.save()
    }

    private func validateUniqueActiveTitle(_ title: String) throws {
        let exists = try context.fetch(FetchDescriptor<ProjectArea>()).contains {
            $0.archivedAt == nil && $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame
        }
        if exists { throw SyncError.duplicateProjectTitle }
    }
}
