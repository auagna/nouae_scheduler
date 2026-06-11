import Foundation

enum PromptExportType: String, CaseIterable, Identifiable {
    case projectAnalysis
    case weeklyReview
    case personalOperatingReport
    case flowRelationshipAnalysis
    case logPatternReview
    case projectTemplateImprovement
    case projectVisionBoardReview
    case planRhythmReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .projectAnalysis: return "Project Analysis"
        case .weeklyReview: return "Weekly Review"
        case .personalOperatingReport: return "Personal Operating Report"
        case .flowRelationshipAnalysis: return "Flow Relationship Analysis"
        case .logPatternReview: return "Log Pattern Review"
        case .projectTemplateImprovement: return "Project Template Improvement"
        case .projectVisionBoardReview: return "Project Vision Board Review"
        case .planRhythmReview: return "Plan Rhythm Review"
        }
    }

    var promptRole: String {
        "Act as an analyst, coach, and strategist. Do not act as a chatbot or secretary."
    }
}

struct PromptBuilderService {
    func build(
        type: PromptExportType,
        selectedProjectId: UUID?,
        areas: [ProjectArea],
        projects: [Project],
        rawTasks: [RawTask],
        workBlocks: [WorkBlock],
        notes: [ProjectNote],
        logs: [ProjectLog],
        adjustments: [NextAdjustment]
    ) -> String {
        let selectedProject = selectedProjectId.flatMap { id in projects.first { $0.id == id } }
        let scopedProjects = selectedProject.map { [$0] } ?? projects
        let scopedProjectIds = Set(scopedProjects.map(\.id))
        let scopedTasks = rawTasks.filter { task in
            guard let projectId = task.projectId else { return selectedProject == nil }
            return scopedProjectIds.contains(projectId)
        }
        let scopedBlocks = workBlocks.filter { block in
            guard let projectId = block.projectId else { return selectedProject == nil }
            return scopedProjectIds.contains(projectId)
        }
        let scopedNotes = notes.filter { note in
            guard let projectId = note.projectId else { return selectedProject == nil }
            return scopedProjectIds.contains(projectId)
        }
        let scopedLogs = logs.filter { log in
            guard let projectId = log.projectId else { return selectedProject == nil }
            return scopedProjectIds.contains(projectId)
        }
        let scopedAdjustments = adjustments.filter { adjustment in
            guard let projectId = adjustment.projectId else { return selectedProject == nil }
            return scopedProjectIds.contains(projectId)
        }

        return [
            header(type: type, selectedProject: selectedProject),
            operatingContext(type: type),
            areaSection(areas: areas, projects: projects),
            projectSection(projects: scopedProjects, areas: areas),
            taskSection(tasks: scopedTasks),
            workBlockSection(blocks: scopedBlocks),
            noteSection(notes: scopedNotes),
            logSection(logs: scopedLogs),
            adjustmentSection(adjustments: scopedAdjustments),
            trackerSummary(blocks: scopedBlocks, logs: scopedLogs),
            analysisQuestions(type: type)
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    private func header(type: PromptExportType, selectedProject: Project?) -> String {
        var lines = [
            "# nou ae \(type.title)",
            "",
            type.promptRole,
            "Analyze patterns, contradictions, blind spots, opportunities, adjustments, and synthesis.",
            "Do not overpraise. Keep the output concrete, calm, and operational."
        ]
        if let selectedProject {
            lines.append("Scope: Project - \(selectedProject.title)")
        } else {
            lines.append("Scope: Entire personal operating system")
        }
        return lines.joined(separator: "\n")
    }

    private func operatingContext(type: PromptExportType) -> String {
        """
        ## Operating Frame
        nou ae is a Personal Operating System, not a productivity app.
        Core loop: Observe -> Act -> Reflect -> Synthesize -> Become.
        Current prompt type: \(type.title).
        """
    }

    private func areaSection(areas: [ProjectArea], projects: [Project]) -> String {
        guard !areas.isEmpty else { return "## Areas\nNo areas recorded." }
        let lines = areas.map { area in
            let projectCount = projects.filter { $0.areaId == area.id }.count
            return "- \(area.title): \(projectCount) projects, calendar=\(area.calendarTitle ?? "missing"), reminders=\(area.reminderListTitle ?? "missing"), sync=\(area.syncState.title)"
        }
        var section = ["## Areas"]
        section.append(contentsOf: lines)
        return section.joined(separator: "\n")
    }

    private func projectSection(projects: [Project], areas: [ProjectArea]) -> String {
        guard !projects.isEmpty else { return "## Projects\nNo projects in scope." }
        let lines = projects.map { project in
            let areaTitle = project.areaId.flatMap { id in areas.first { $0.id == id }?.title } ?? "Unassigned"
            return """
            - \(project.title)
              area: \(areaTitle)
              type: \(project.type.title)
              status: \(project.status.title)
              goal: \(project.goal.isEmpty ? "empty" : project.goal)
              calendar: \(project.calendarTitle ?? "area/default")
              reminder list: \(project.reminderListTitle ?? "area/default")
            """
        }
        var section = ["## Projects"]
        section.append(contentsOf: lines)
        return section.joined(separator: "\n")
    }

    private func taskSection(tasks: [RawTask]) -> String {
        guard !tasks.isEmpty else { return "## RawTasks\nNo inbox tasks in scope." }
        let lines = tasks.prefix(20).map { task in
            "- \(task.title) | converted=\(task.isConvertedToBlock) | reminder=\(task.reminderIdentifier == nil ? "missing" : "linked") | created=\(shortDate(task.createdAt))"
        }
        var section = ["## RawTasks"]
        section.append(contentsOf: lines)
        return section.joined(separator: "\n")
    }

    private func workBlockSection(blocks: [WorkBlock]) -> String {
        guard !blocks.isEmpty else { return "## WorkBlocks\nNo time blocks in scope." }
        let lines = blocks.prefix(30).map { block in
            "- \(block.title) | \(shortDateTime(block.startAt)) -> \(shortDateTime(block.endAt)) | state=\(block.executionState.title) | sync=\(block.syncState.title)"
        }
        var section = ["## WorkBlocks"]
        section.append(contentsOf: lines)
        return section.joined(separator: "\n")
    }

    private func noteSection(notes: [ProjectNote]) -> String {
        guard !notes.isEmpty else { return "## Project Notes\nNo notes in scope." }
        let lines = notes.prefix(16).map { note in
            let preview = note.content.replacingOccurrences(of: "\n", with: " ").prefix(180)
            return "- \(note.noteType.title) / \(note.title): \(preview)"
        }
        var section = ["## Project Notes"]
        section.append(contentsOf: lines)
        return section.joined(separator: "\n")
    }

    private func logSection(logs: [ProjectLog]) -> String {
        guard !logs.isEmpty else { return "## Logs\nNo logs in scope." }
        let lines = logs.prefix(20).map { log in
            let mood = log.moodTags.isEmpty ? "-" : log.moodTags.joined(separator: ", ")
            let blockers = log.blockerTags.isEmpty ? "-" : log.blockerTags.joined(separator: ", ")
            return "- \(shortDate(log.createdAt)) \(log.logType.title) | focus=\(log.focusLevel.map { String($0) } ?? "-") | mood=\(mood) | blockers=\(blockers) | next=\(log.nextAdjustment)"
        }
        var section = ["## Logs"]
        section.append(contentsOf: lines)
        return section.joined(separator: "\n")
    }

    private func adjustmentSection(adjustments: [NextAdjustment]) -> String {
        guard !adjustments.isEmpty else { return "## Next Adjustments\nNo active adjustments in scope." }
        let lines = adjustments.prefix(12).map { adjustment in
            "- \(adjustment.content) | active=\(adjustment.isActive) | created=\(shortDate(adjustment.createdAt))"
        }
        var section = ["## Next Adjustments"]
        section.append(contentsOf: lines)
        return section.joined(separator: "\n")
    }

    private func trackerSummary(blocks: [WorkBlock], logs: [ProjectLog]) -> String {
        let completed = blocks.filter { $0.executionState == .completed }.count
        let delayed = blocks.filter { $0.executionState == .delayed }.count
        let stopped = blocks.filter { $0.executionState == .stopped }.count
        let averageFocus = average(logs.compactMap(\.focusLevel))
        let topMood = topTag(logs.flatMap(\.moodTags)) ?? "-"
        let topBlocker = topTag(logs.flatMap(\.blockerTags)) ?? "-"
        return """
        ## Tracker Summary
        completed blocks: \(completed)
        delayed blocks: \(delayed)
        stopped blocks: \(stopped)
        logs: \(logs.count)
        average focus: \(averageFocus)
        top mood tag: \(topMood)
        top blocker tag: \(topBlocker)
        """
    }

    private func analysisQuestions(type: PromptExportType) -> String {
        let shared = [
            "What pattern is visible but easy to ignore?",
            "What assumption is currently unchallenged?",
            "What evidence contradicts the current direction?",
            "Which action has the strongest relationship with progress?",
            "What should be adjusted next?"
        ]
        let specific: [String]
        switch type {
        case .projectAnalysis:
            specific = ["What is this project really trying to become?", "Where is the project stuck operationally?"]
        case .weeklyReview:
            specific = ["What changed this week?", "Which rhythm should be repeated next week?"]
        case .personalOperatingReport:
            specific = ["What is the current operating state?", "What needs less force and more design?"]
        case .flowRelationshipAnalysis:
            specific = ["Which behavior seems connected to better outcomes?", "Which relation needs more evidence?"]
        case .logPatternReview:
            specific = ["Which mood or blocker repeats?", "What reflection should become a next adjustment?"]
        case .projectTemplateImprovement:
            specific = ["Which section is missing from the project template?", "Which section is not earning its place?"]
        case .projectVisionBoardReview:
            specific = ["What vision is emerging from the notes?", "What output would make the thinking visible?"]
        case .planRhythmReview:
            specific = ["Which block length works best?", "Where does the plan overestimate available energy?"]
        }
        var questions = specific
        questions.append(contentsOf: shared)
        var section = ["## Questions To Answer"]
        section.append(contentsOf: questions.map { "- \($0)" })
        return section.joined(separator: "\n")
    }

    private func average(_ values: [Int]) -> String {
        guard !values.isEmpty else { return "-" }
        let value = Double(values.reduce(0, +)) / Double(values.count)
        return String(format: "%.1f", value)
    }

    private func topTag(_ tags: [String]) -> String? {
        Dictionary(grouping: tags, by: { $0 })
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
            .first?.key
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month().day())
    }

    private func shortDateTime(_ date: Date) -> String {
        date.formatted(.dateTime.month().day().hour().minute())
    }
}
