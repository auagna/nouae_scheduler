import Foundation
import SwiftData

@MainActor
final class ProjectStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func createProject(title: String, type: ProjectType, status: ProjectStatus, goal: String, calendarSyncManager: CalendarSyncManager) async throws -> Project {
        let project = Project(title: title.trimmingCharacters(in: .whitespacesAndNewlines), type: type, status: status, goal: goal)
        context.insert(project)
        createDefaultSections(projectId: project.id)
        try context.save()
        project.syncState = .syncing
        try context.save()
        do {
            let calendar = try await calendarSyncManager.createCalendar(title: project.title)
            project.calendarIdentifier = calendar.id
            project.calendarTitle = calendar.title
            project.calendarColorHex = calendar.colorHex
            project.syncState = .synced
            project.updatedAt = Date()
            try context.save()
        } catch {
            project.syncState = .failed
            project.updatedAt = Date()
            try? context.save()
            throw error
        }
        return project
    }

    func createLocalProject(title: String, type: ProjectType = .personal, status: ProjectStatus = .planning, goal: String = "") throws -> Project {
        let project = Project(title: title, type: type, status: status, goal: goal)
        context.insert(project)
        createDefaultSections(projectId: project.id)
        try context.save()
        return project
    }

    func updateProjectStatus(project: Project, status: ProjectStatus) throws { project.status = status; project.archivedAt = status == .archived ? Date() : project.archivedAt; updateProjectUpdatedAt(project: project); try context.save() }
    func updateProjectGoal(project: Project, goal: String) throws { project.goal = goal; updateProjectUpdatedAt(project: project); try context.save() }
    func updateProjectUpdatedAt(project: Project) { project.updatedAt = Date() }
    func fetchProjectsByStatus(status: ProjectStatus) throws -> [Project] { try context.fetch(FetchDescriptor<Project>()).filter { $0.status == status } }
    func archiveProjectsWithMissingCalendars(calendarSyncManager: CalendarSyncManager) async throws { try await calendarSyncManager.archiveProjectsWithMissingCalendars(context: context) }
    func addMemoSection(projectId: UUID, title: String, content: String) throws { let order = try context.fetch(FetchDescriptor<ProjectMemoSection>()).filter { $0.projectId == projectId }.count; context.insert(ProjectMemoSection(projectId: projectId, title: title, content: content, order: order)); try context.save() }

    private func createDefaultSections(projectId: UUID) {
        for (index, title) in ["목표", "Inbox", "메모", "다음 조정"].enumerated() { context.insert(ProjectMemoSection(projectId: projectId, title: title, order: index)) }
    }
}
