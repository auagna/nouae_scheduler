import Foundation

@MainActor
final class ProjectStore: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var rawTasks: [RawTask] = []
    @Published private(set) var pageSections: [ProjectPageSection] = []
    @Published private(set) var logs: [ProjectLog] = []
    @Published private(set) var adjustments: [NextAdjustment] = []
    @Published var message: String?

    private let projectsKey = "nouae.projects"
    private let rawTasksKey = "nouae.rawTasks"
    private let sectionsKey = "nouae.projectPageSections"
    private let logsKey = "nouae.projectLogs"
    private let adjustmentsKey = "nouae.nextAdjustments"
    private let defaults = UserDefaults.standard

    init() {
        loadAll()
    }

    var activeProjects: [Project] {
        projects
            .filter { !$0.isArchived }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func projects(for category: ScheduleCategory?, status: ProjectStatus? = nil) -> [Project] {
        activeProjects.filter { project in
            let categoryMatches = category == nil || project.category == category
            let statusMatches = status == nil || project.status == status
            return categoryMatches && statusMatches
        }
    }

    func project(id: UUID?) -> Project? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    @discardableResult
    func createProject(title: String, type: ProjectType, category: ScheduleCategory, purpose: String, note: String?, calendarIdentifier: String?) -> Project? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            message = "프로젝트 이름을 입력해 주세요."
            return nil
        }

        let project = Project(
            title: cleanTitle,
            type: type,
            category: category,
            purpose: purpose.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            calendarIdentifier: calendarIdentifier
        )
        projects.append(project)
        pageSections.append(contentsOf: defaultSections(for: project))
        saveAll()
        message = nil
        return project
    }

    func updateStatus(_ status: ProjectStatus, for project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].status = status
        projects[index].updatedAt = Date()
        if status == .archived {
            projects[index].archivedAt = Date()
        }
        saveAll()
    }

    func archive(_ project: Project) {
        updateStatus(.archived, for: project)
    }

    func addRawTask(title: String, memo: String?, project: Project, dueAt: Date? = nil) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        rawTasks.append(RawTask(title: cleanTitle, memo: memo, category: project.category, projectId: project.id, dueAt: dueAt))
        saveAll()
    }

    func rawTasks(for project: Project) -> [RawTask] {
        rawTasks
            .filter { $0.projectId == project.id && !$0.isConvertedToBlock }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func pageSections(for project: Project) -> [ProjectPageSection] {
        pageSections
            .filter { $0.projectId == project.id }
            .sorted { $0.order < $1.order }
    }

    func addPageSection(project: Project, title: String, content: String) {
        let nextOrder = (pageSections(for: project).map(\.order).max() ?? -1) + 1
        pageSections.append(ProjectPageSection(projectId: project.id, title: title, content: content, order: nextOrder, isGenerated: false))
        saveAll()
    }

    func updatePageSection(_ section: ProjectPageSection, title: String, content: String) {
        guard let index = pageSections.firstIndex(where: { $0.id == section.id }) else { return }
        pageSections[index].title = title
        pageSections[index].content = content
        pageSections[index].updatedAt = Date()
        saveAll()
    }

    func moveSection(_ section: ProjectPageSection, direction: Int) {
        let sections = pageSections(for: Project(id: section.projectId, title: "", type: .work, category: .work))
        guard let currentPosition = sections.firstIndex(where: { $0.id == section.id }) else { return }
        let newPosition = max(0, min(sections.count - 1, currentPosition + direction))
        guard currentPosition != newPosition else { return }
        var reordered = sections
        let item = reordered.remove(at: currentPosition)
        reordered.insert(item, at: newPosition)
        for (order, item) in reordered.enumerated() {
            if let index = pageSections.firstIndex(where: { $0.id == item.id }) {
                pageSections[index].order = order
                pageSections[index].updatedAt = Date()
            }
        }
        saveAll()
    }

    func addLog(project: Project, title: String, content: String, mood: String?, linkedWorkBlockId: UUID?) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty || !cleanContent.isEmpty else { return }
        logs.append(ProjectLog(projectId: project.id, title: cleanTitle.isEmpty ? "기록" : cleanTitle, content: cleanContent, mood: mood, linkedWorkBlockId: linkedWorkBlockId))
        saveAll()
    }

    func logs(for project: Project) -> [ProjectLog] {
        logs.filter { $0.projectId == project.id }.sorted { $0.createdAt > $1.createdAt }
    }

    func setNextAdjustment(project: Project, content: String) {
        for index in adjustments.indices where adjustments[index].projectId == project.id {
            adjustments[index].isActive = false
        }
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanContent.isEmpty else {
            saveAll()
            return
        }
        adjustments.append(NextAdjustment(projectId: project.id, content: cleanContent))
        saveAll()
    }

    func activeAdjustment(for project: Project) -> NextAdjustment? {
        adjustments
            .filter { $0.projectId == project.id && $0.isActive }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func summary(for project: Project) -> ProjectDashboardSummary {
        let projectBlocks = TimeBlockStore.loadPersistedBlocks().filter { $0.projectId == project.id }
        let calendar = Calendar.current
        let now = Date()
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        let totalMinutes = projectBlocks.reduce(0) { $0 + $1.durationMinutes }
        let todayMinutes = projectBlocks.filter { calendar.isDate($0.startAt, inSameDayAs: now) }.reduce(0) { $0 + $1.durationMinutes }
        let weekMinutes = projectBlocks.filter { block in
            guard let weekInterval else { return false }
            return block.startAt >= weekInterval.start && block.startAt < weekInterval.end
        }.reduce(0) { $0 + $1.durationMinutes }
        let lastWorkedAt = projectBlocks.map(\.endAt).max()
        return ProjectDashboardSummary(projectId: project.id, totalBlocks: projectBlocks.count, totalMinutes: totalMinutes, todayMinutes: todayMinutes, weekMinutes: weekMinutes, lastWorkedAt: lastWorkedAt)
    }

    func blocks(for project: Project) -> [TimeBlock] {
        TimeBlockStore.loadPersistedBlocks()
            .filter { $0.projectId == project.id }
            .sorted { $0.startAt > $1.startAt }
    }

    func reportSummary(for project: Project) -> ProjectReportSummary {
        let summary = summary(for: project)
        return ProjectReportSummary(
            projectId: project.id,
            generatedAt: Date(),
            headline: "\(project.title) 리포트",
            workMinutes: summary.totalMinutes,
            rawTaskCount: rawTasks(for: project).count,
            logCount: logs(for: project).count,
            activeAdjustment: activeAdjustment(for: project)?.content
        )
    }

    func aiBriefPrompt(for project: Project) -> String {
        let sections = pageSections(for: project).map { "- \($0.title): \($0.content)" }.joined(separator: "\n")
        let tasks = rawTasks(for: project).map { "- \($0.title)" }.joined(separator: "\n")
        let adjustment = activeAdjustment(for: project)?.content ?? "없음"
        return """
        nouae Scheduler Project Brief Builder

        Project: \(project.title)
        Type: \(project.type.rawValue)
        Category: \(project.category.rawValue)
        Status: \(project.status.rawValue)
        Purpose: \(project.purpose)
        Note: \(project.note ?? "")

        Page Sections:
        \(sections.isEmpty ? "없음" : sections)

        RawTask Inbox:
        \(tasks.isEmpty ? "없음" : tasks)

        Next Adjustment:
        \(adjustment)

        요청: 이 프로젝트의 현재 목적, 다음 작업, 조정 포인트, 리스크, 1주 액션 플랜을 간결하게 정리해줘.
        """
    }

    private func defaultSections(for project: Project) -> [ProjectPageSection] {
        let templates: [(String, String)]
        switch project.type {
        case .study:
            templates = [("학습 목표", project.purpose), ("핵심 질문", "무엇을 이해하면 성공인가?"), ("다음 학습", "다음에 확인할 자료와 연습을 적습니다.")]
        case .work:
            templates = [("목적", project.purpose), ("범위", "이번 프로젝트에서 다룰 일과 제외할 일을 구분합니다."), ("다음 실행", "가장 가까운 실행 단위를 적습니다.")]
        case .exercise:
            templates = [("운동 목적", project.purpose), ("루틴", "반복할 운동과 빈도를 적습니다."), ("컨디션 체크", "몸 상태와 조정점을 적습니다.")]
        case .creative:
            templates = [("콘셉트", project.purpose), ("재료", "필요한 아이디어, 자료, 도구를 적습니다."), ("다음 제작", "다음 제작 단계를 적습니다.")]
        case .portfolio:
            templates = [("보여줄 가치", project.purpose), ("구성", "포트폴리오 섹션과 증거를 적습니다."), ("개선점", "다음 수정 포인트를 적습니다.")]
        case .personal:
            templates = [("목적", project.purpose), ("현재 상태", "지금 상황을 적습니다."), ("다음 조정", "가볍게 바꿀 한 가지를 적습니다.")]
        }
        return templates.enumerated().map { index, template in
            ProjectPageSection(projectId: project.id, title: template.0, content: template.1, order: index, isGenerated: true)
        }
    }

    private func loadAll() {
        projects = load([Project].self, key: projectsKey) ?? []
        rawTasks = load([RawTask].self, key: rawTasksKey) ?? []
        pageSections = load([ProjectPageSection].self, key: sectionsKey) ?? []
        logs = load([ProjectLog].self, key: logsKey) ?? []
        adjustments = load([NextAdjustment].self, key: adjustmentsKey) ?? []
    }

    private func saveAll() {
        save(projects, key: projectsKey)
        save(rawTasks, key: rawTasksKey)
        save(pageSections, key: sectionsKey)
        save(logs, key: logsKey)
        save(adjustments, key: adjustmentsKey)
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            message = "프로젝트 데이터를 저장하지 못했습니다."
            return
        }
        defaults.set(data, forKey: key)
    }
}
