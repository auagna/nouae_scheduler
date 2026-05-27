import Foundation

@MainActor
final class ProjectStore: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published var message: String?

    private let defaultsKey = "nouae.projects"
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    var activeProjects: [Project] {
        projects
            .filter { !$0.isArchived }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func projects(for category: ScheduleCategory?) -> [Project] {
        guard let category else { return activeProjects }
        return activeProjects.filter { $0.category == category }
    }

    func project(id: UUID?) -> Project? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    func createProject(title: String, category: ScheduleCategory, note: String?, calendarIdentifier: String?) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            message = "프로젝트 이름을 입력해 주세요."
            return
        }

        let project = Project(
            title: cleanTitle,
            category: category,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            calendarIdentifier: calendarIdentifier
        )
        projects.append(project)
        save()
        message = nil
    }

    func updateProject(_ project: Project, title: String, category: ScheduleCategory, note: String?, calendarIdentifier: String?) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            message = "프로젝트 이름을 입력해 주세요."
            return
        }
        projects[index].title = cleanTitle
        projects[index].category = category
        projects[index].note = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        projects[index].calendarIdentifier = calendarIdentifier
        projects[index].updatedAt = Date()
        save()
    }

    func archive(_ project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].isArchived = true
        projects[index].updatedAt = Date()
        save()
    }

    func summary(for project: Project) -> ProjectDashboardSummary {
        let projectBlocks = TimeBlockStore.loadPersistedBlocks().filter { $0.projectId == project.id }
        let calendar = Calendar.current
        let now = Date()
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)

        let totalMinutes = projectBlocks.reduce(0) { $0 + $1.durationMinutes }
        let todayMinutes = projectBlocks
            .filter { calendar.isDate($0.startAt, inSameDayAs: now) }
            .reduce(0) { $0 + $1.durationMinutes }
        let weekMinutes = projectBlocks
            .filter { block in
                guard let weekInterval else { return false }
                return block.startAt >= weekInterval.start && block.startAt < weekInterval.end
            }
            .reduce(0) { $0 + $1.durationMinutes }
        let lastWorkedAt = projectBlocks.map(\.endAt).max()

        return ProjectDashboardSummary(
            projectId: project.id,
            totalBlocks: projectBlocks.count,
            totalMinutes: totalMinutes,
            todayMinutes: todayMinutes,
            weekMinutes: weekMinutes,
            lastWorkedAt: lastWorkedAt
        )
    }

    func blocks(for project: Project) -> [TimeBlock] {
        TimeBlockStore.loadPersistedBlocks()
            .filter { $0.projectId == project.id }
            .sorted { $0.startAt > $1.startAt }
    }

    private func load() {
        guard let data = defaults.data(forKey: defaultsKey) else {
            projects = []
            return
        }

        do {
            projects = try JSONDecoder().decode([Project].self, from: data)
        } catch {
            projects = []
            message = "프로젝트 데이터를 불러오지 못했습니다."
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(projects)
            defaults.set(data, forKey: defaultsKey)
        } catch {
            message = "프로젝트 저장에 실패했습니다."
        }
    }
}
