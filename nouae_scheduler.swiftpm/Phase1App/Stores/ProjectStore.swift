import Combine
import Foundation
import SwiftData

@MainActor
final class ProjectStore: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    @discardableResult
    func createProject(title: String, type: ProjectType = .personal, goal: String = "") throws -> Project {
        let project = Project(title: title.trimmingCharacters(in: .whitespacesAndNewlines), type: type, goal: goal)
        modelContext.insert(project)
        for (index, title) in ["목표", "Inbox", "메모", "다음 조정"].enumerated() {
            modelContext.insert(ProjectMemoSection(projectId: project.id, title: title, order: index))
        }
        try modelContext.save()
        return project
    }

    func fetchProjects() throws -> [Project] {
        try modelContext.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
    }

    func findProject(id: UUID) throws -> Project? { try fetchProjects().first { $0.id == id } }

    func updateStatus(_ project: Project, status: ProjectStatus) throws {
        project.status = status
        project.updatedAt = Date()
        if status == .archived { project.archivedAt = Date() }
        try modelContext.save()
    }

    func archiveProject(_ project: Project) throws { try updateStatus(project, status: .archived) }
}
