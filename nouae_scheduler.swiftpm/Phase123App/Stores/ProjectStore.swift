import Foundation
import SwiftData

@MainActor
final class ProjectStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func createProjectInArea(title: String, type: ProjectType, status: ProjectStatus, goal: String, area: ProjectArea?) throws -> Project {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw SyncError.invalidTitle }
        try validateUniqueActiveTitle(trimmedTitle)
        let project = Project(
            title: trimmedTitle,
            type: type,
            status: status,
            goal: goal,
            areaId: area?.id,
            calendarIdentifier: area?.calendarIdentifier,
            calendarTitle: area?.calendarTitle,
            calendarColorHex: area?.calendarColorHex,
            syncState: area == nil ? .local : area?.syncState ?? .local
        )
        context.insert(project)
        createDefaultSections(project: project)
        try context.save()
        return project
    }

    func createLocalProject(title: String, type: ProjectType = .personal, status: ProjectStatus = .planning, goal: String = "", area: ProjectArea? = nil) throws -> Project {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw SyncError.invalidTitle }
        try validateUniqueActiveTitle(trimmedTitle)
        let project = Project(
            title: trimmedTitle,
            type: type,
            status: status,
            goal: goal,
            areaId: area?.id,
            calendarIdentifier: area?.calendarIdentifier,
            calendarTitle: area?.calendarTitle,
            calendarColorHex: area?.calendarColorHex
        )
        context.insert(project)
        createDefaultSections(project: project)
        try context.save()
        return project
    }

    func updateProjectStatus(project: Project, status: ProjectStatus) throws {
        project.status = status
        project.archivedAt = status == .archived ? Date() : project.archivedAt
        updateProjectUpdatedAt(project: project)
        try context.save()
    }

    func updateProjectGoal(project: Project, goal: String) throws {
        project.goal = goal
        updateProjectUpdatedAt(project: project)
        try context.save()
    }

    func assignProject(_ project: Project, to area: ProjectArea?) throws {
        project.areaId = area?.id
        project.calendarIdentifier = area?.calendarIdentifier
        project.calendarTitle = area?.calendarTitle
        project.calendarColorHex = area?.calendarColorHex
        project.syncState = area?.syncState ?? .local
        updateProjectUpdatedAt(project: project)
        try context.save()
    }

    func updateProjectUpdatedAt(project: Project) { project.updatedAt = Date() }

    func fetchProjectsByStatus(status: ProjectStatus) throws -> [Project] {
        try context.fetch(FetchDescriptor<Project>()).filter { $0.status == status }
    }

    func archiveProjectsWithMissingCalendars(calendarSyncManager: CalendarSyncManager) async throws {
        try await calendarSyncManager.archiveProjectsWithMissingCalendars(context: context)
    }

    func addMemoSection(projectId: UUID, title: String, content: String) throws {
        let order = try context.fetch(FetchDescriptor<ProjectMemoSection>()).filter { $0.projectId == projectId }.count
        context.insert(ProjectMemoSection(projectId: projectId, title: title.trimmingCharacters(in: .whitespacesAndNewlines), content: content.trimmingCharacters(in: .whitespacesAndNewlines), order: order))
        try context.save()
    }

    func updateMemoSection(section: ProjectMemoSection, title: String, content: String) throws {
        section.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        section.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        section.updatedAt = Date()
        try context.save()
    }

    private func validateUniqueActiveTitle(_ title: String) throws {
        let exists = try context.fetch(FetchDescriptor<Project>()).contains {
            $0.status != .archived && $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame
        }
        if exists { throw SyncError.duplicateProjectTitle }
    }

    private func createDefaultSections(project: Project) {
        for (index, section) in TemplateDatabase.sections(for: project.type).enumerated() {
            context.insert(ProjectMemoSection(projectId: project.id, title: section.title, content: section.content, order: index))
        }
    }
}
