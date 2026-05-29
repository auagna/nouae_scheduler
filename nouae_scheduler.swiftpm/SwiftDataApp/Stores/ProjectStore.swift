import Foundation
import SwiftData

@MainActor
final class ProjectStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func createProject(
        title: String,
        type: ProjectType = .personal,
        status: ProjectStatus = .planning,
        goal: String = "",
        calendarIdentifier: String? = nil,
        calendarTitle: String? = nil,
        calendarColorHex: String? = nil
    ) throws -> Project {
        let project = Project(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            status: status,
            goal: goal,
            calendarIdentifier: calendarIdentifier,
            calendarTitle: calendarTitle,
            calendarColorHex: calendarColorHex
        )
        modelContext.insert(project)
        createDefaultSectionsForProject(project)
        try save()
        return project
    }

    func updateProject(
        _ project: Project,
        title: String? = nil,
        type: ProjectType? = nil,
        status: ProjectStatus? = nil,
        goal: String? = nil
    ) throws {
        if let title { project.title = title.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let type { project.type = type }
        if let status { project.status = status }
        if let goal { project.goal = goal }
        project.updatedAt = Date()
        try save()
    }

    func archiveProject(_ project: Project) throws {
        project.status = .archived
        project.archivedAt = Date()
        project.updatedAt = Date()
        try save()
    }

    func archiveProjectForBrokenCalendarLink(_ project: Project) throws {
        project.calendarIdentifier = nil
        project.calendarTitle = nil
        project.calendarColorHex = nil
        try archiveProject(project)
    }

    func fetchProjects() throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func fetchActiveProjects() throws -> [Project] {
        try fetchProjects().filter { !$0.isArchived && $0.status != .completed }
    }

    func findProject(id: UUID) throws -> Project? {
        try fetchProjects().first { $0.id == id }
    }

    func updateCalendarLink(
        project: Project,
        calendarIdentifier: String?,
        calendarTitle: String?,
        calendarColorHex: String?
    ) throws {
        project.calendarIdentifier = calendarIdentifier
        project.calendarTitle = calendarTitle
        project.calendarColorHex = calendarColorHex
        project.updatedAt = Date()
        try save()
    }

    func createDefaultSectionsForProject(_ project: Project) {
        let existing = (try? fetchMemoSections(projectId: project.id)) ?? []
        guard existing.isEmpty else { return }
        let titles = ["목표", "Inbox", "메모", "다음 조정"]
        for (index, title) in titles.enumerated() {
            modelContext.insert(ProjectMemoSection(projectId: project.id, title: title, order: index))
        }
    }

    func fetchMemoSections(projectId: UUID) throws -> [ProjectMemoSection] {
        let descriptor = FetchDescriptor<ProjectMemoSection>(sortBy: [SortDescriptor(\.order)])
        return try modelContext.fetch(descriptor).filter { $0.projectId == projectId }
    }

    private func save() throws {
        try modelContext.save()
    }
}
