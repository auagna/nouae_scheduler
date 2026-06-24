import SwiftData
import SwiftUI

struct ProjectDashboardView: View {
    let project: Project

    @EnvironmentObject private var stores: AppStores
    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]
    @Query(sort: \ProjectArea.updatedAt, order: .reverse) private var areas: [ProjectArea]
    @Query private var blocks: [WorkBlock]
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \ProjectMemoSection.order) private var sections: [ProjectMemoSection]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]
    @Query(sort: \ProjectBoardItem.updatedAt, order: .reverse) private var boardItems: [ProjectBoardItem]
    @Query(sort: \ProjectNote.updatedAt, order: .reverse) private var notes: [ProjectNote]

    @AppStorage("nouae.sharedSelectedDate") private var sharedSelectedDate = Date().timeIntervalSince1970
    @State private var selectedQueue: ProjectDashboardQueueKind = .next
    @State private var showingPromptExport = false
    @State private var showingLogEditor = false
    @State private var logTargetWorkBlockId: UUID?

    var body: some View {
        GeometryReader { geometry in
            AppScreenContainer(spacing: 16) {
                ProjectMVPHeader(
                    projectTitle: project.title,
                    areaName: areaTitle,
                    projectType: project.type.title,
                    lifecycleTitle: lifecycleTitle,
                    areaColor: areaColor,
                    calendarState: areaCalendarState,
                    reminderState: areaReminderState,
                    lastActivityText: lastActivityText,
                    isArchived: isArchived
                )

                #if DEBUG
                Text("ProjectMVPDashboardLayout ACTIVE L17")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red, in: Capsule())
                #endif

                if geometry.size.width >= 900 {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            ProjectMVPCurrentFocusPanel(
                                focus: currentFocusSnapshot,
                                suggestedNext: nextQueueItems.first,
                                accentColor: areaColor,
                                onStart: startCurrentFocus,
                                onComplete: completeCurrentFocus,
                                onDelay: delayCurrentFocus,
                                onStop: stopCurrentFocus,
                                onOpenPlan: openCurrentFocusInPlan
                            )

                            ProjectMVPOperationalQueuePanel(
                                selectedKind: $selectedQueue,
                                counts: queueCounts,
                                items: queueItems(for: selectedQueue),
                                onOpenPlan: openQueueItemInPlan,
                                onWriteLog: openLogForQueueItem
                            )

                            ProjectMVPTodayTimelinePanel(
                                blocks: todayTimelineBlocks,
                                focusBlockId: currentFocusBlock?.id,
                                accentColor: areaColor,
                                onOpenPlan: openTodayInPlan
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                        VStack(alignment: .leading, spacing: 16) {
                            ProjectMVPBriefPanel(
                                goal: project.goal,
                                sections: projectBriefSections,
                                onAddMissingSections: addMissingTemplateSections
                            )

                            ProjectMVPNextAdjustmentPanel(active: activeAdjustments, recent: recentAdjustments)
                            ProjectMVPSpacePreviewPanel(project: project, areas: areas, projects: allProjects, notes: projectNotes, boardItems: projectBoardItems)
                            ProjectMVPRecentReflectionPanel(logs: recentProjectLogs, onWriteLog: openProjectLog)
                            ProjectMVPCompactTrackerPanel(summary: trackerSummary, accentColor: areaColor)
                            ProjectMVPAttentionPanel(items: attentionItems, compactInsight: compactInsight)
                            ModuleHostView(placement: .projectDashboardContext, projectId: project.id, layoutStyle: .compact)
                        }
                        .frame(width: max(320, geometry.size.width * 0.34), alignment: .topLeading)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ProjectMVPCurrentFocusPanel(
                            focus: currentFocusSnapshot,
                            suggestedNext: nextQueueItems.first,
                            accentColor: areaColor,
                            onStart: startCurrentFocus,
                            onComplete: completeCurrentFocus,
                            onDelay: delayCurrentFocus,
                            onStop: stopCurrentFocus,
                            onOpenPlan: openCurrentFocusInPlan
                        )

                        ProjectMVPOperationalQueuePanel(
                            selectedKind: $selectedQueue,
                            counts: queueCounts,
                            items: queueItems(for: selectedQueue),
                            onOpenPlan: openQueueItemInPlan,
                            onWriteLog: openLogForQueueItem
                        )

                        ProjectMVPTodayTimelinePanel(
                            blocks: todayTimelineBlocks,
                            focusBlockId: currentFocusBlock?.id,
                            accentColor: areaColor,
                            onOpenPlan: openTodayInPlan
                        )

                        ProjectMVPBriefPanel(
                            goal: project.goal,
                            sections: projectBriefSections,
                            onAddMissingSections: addMissingTemplateSections
                        )

                        ProjectMVPNextAdjustmentPanel(active: activeAdjustments, recent: recentAdjustments)
                        ProjectMVPSpacePreviewPanel(project: project, areas: areas, projects: allProjects, notes: projectNotes, boardItems: projectBoardItems)
                        ProjectMVPRecentReflectionPanel(logs: recentProjectLogs, onWriteLog: openProjectLog)
                        ProjectMVPCompactTrackerPanel(summary: trackerSummary, accentColor: areaColor)
                        ProjectMVPAttentionPanel(items: attentionItems, compactInsight: compactInsight)
                        ModuleHostView(placement: .projectDashboardContext, projectId: project.id, layoutStyle: .compact)
                    }
                }
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingPromptExport = true
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }
                .accessibilityLabel("Project Analysis Prompt")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Planned") { changeStatus(.planning) }
                    Button("Active") { changeStatus(.active) }
                    Button("Completed") { changeStatus(.completed) }
                    Divider()
                    Button(isArchived ? "Restore to Planned" : "Archive") {
                        changeStatus(isArchived ? .planning : .archived)
                    }
                } label: {
                    Label(lifecycleTitle, systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingPromptExport) {
            PromptExportView(initialType: .projectAnalysis, selectedProjectId: project.id)
        }
        .sheet(isPresented: $showingLogEditor) {
            LogEditorSheet(initialProjectId: project.id, initialWorkBlockId: logTargetWorkBlockId)
        }
    }

    private var projectArea: ProjectArea? {
        guard let areaId = project.areaId else { return nil }
        return areas.first { $0.id == areaId }
    }

    private var areaTitle: String {
        projectArea?.title ?? "Area 미지정"
    }

    private var areaColor: Color {
        Color(calendarHex: projectArea?.calendarColorHex ?? project.calendarColorHex)
    }

    private var areaCalendarState: String {
        if projectArea?.calendarIdentifier != nil || project.calendarIdentifier != nil {
            return (projectArea?.syncState ?? project.syncState).title
        }
        return "미연결"
    }

    private var areaReminderState: String {
        if projectArea?.reminderListIdentifier != nil || project.reminderListIdentifier != nil {
            return (projectArea?.syncState ?? project.syncState).title
        }
        return "미연결"
    }

    private var isArchived: Bool {
        project.archivedAt != nil || project.status == .archived
    }

    private var lifecycleTitle: String {
        if isArchived { return "Archived" }
        if project.status == .completed { return "Completed" }
        if project.status == .active { return "Active" }
        return "Planned"
    }

    private var projectBlocks: [WorkBlock] {
        blocks
            .filter { $0.projectId == project.id }
            .sorted { $0.startAt < $1.startAt }
    }

    private var projectTasks: [RawTask] {
        tasks.filter { $0.projectId == project.id && !$0.isConvertedToBlock }
    }

    private var projectSections: [ProjectMemoSection] {
        sections
            .filter { $0.projectId == project.id }
            .sorted { $0.order < $1.order }
    }

    private var projectLogs: [ProjectLog] {
        logs.filter { $0.projectId == project.id }
    }

    private var projectAdjustments: [NextAdjustment] {
        adjustments.filter { $0.projectId == project.id }
    }

    private var projectBoardItems: [ProjectBoardItem] {
        boardItems.filter { $0.projectId == project.id && !$0.isArchived }
    }

    private var projectNotes: [ProjectNote] {
        notes.filter { $0.projectId == project.id && !$0.isArchived }
    }

    private var recentProjectLogs: [ProjectLog] {
        Array(projectLogs.prefix(3))
    }

    private var activeAdjustments: [NextAdjustment] {
        projectAdjustments.filter(\.isActive)
    }

    private var recentAdjustments: [NextAdjustment] {
        Array(projectAdjustments.filter { !$0.isActive }.prefix(2))
    }

    private var todayRange: (start: Date, end: Date) {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()
        return (start, end)
    }

    private var todayBlocks: [WorkBlock] {
        let range = todayRange
        return projectBlocks.filter { $0.startAt < range.end && $0.endAt > range.start }
    }

    private var currentFocusBlock: WorkBlock? {
        if let running = projectBlocks.first(where: { $0.executionState == .inProgress }) {
            return running
        }

        let now = Date()
        return todayBlocks
            .filter { $0.executionState == .planned }
            .sorted { abs($0.startAt.timeIntervalSince(now)) < abs($1.startAt.timeIntervalSince(now)) }
            .first
    }

    private var todayTimelineBlocks: [WorkBlock] {
        todayBlocks.filter { $0.id != currentFocusBlock?.id }
    }

    private var currentFocusSnapshot: ProjectDashboardFocusSnapshot? {
        if let block = currentFocusBlock {
            return ProjectDashboardFocusSnapshot(
                id: block.id.uuidString,
                title: block.title,
                subtitle: "\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))",
                areaText: areaTitle,
                memo: block.memo,
                stateText: block.executionState.title,
                syncText: block.syncState.title,
                remainingText: remainingText(for: block),
                blockId: block.id
            )
        }

        if let next = nextQueueItems.first {
            return ProjectDashboardFocusSnapshot(
                id: next.id,
                title: next.title,
                subtitle: next.subtitle,
                areaText: areaTitle,
                memo: next.detail,
                stateText: "Next",
                syncText: next.syncText,
                remainingText: nil,
                blockId: next.blockId
            )
        }

        return nil
    }

    private var nextQueueItems: [ProjectDashboardQueueItem] {
        let now = Date()
        let taskItems = projectTasks
            .filter { ($0.scheduledAt ?? .distantPast) <= now }
            .map {
                ProjectDashboardQueueItem(
                    kind: .next,
                    source: .rawTask,
                    sourceId: $0.id,
                    rawTaskId: $0.id,
                    blockId: nil,
                    title: $0.title,
                    subtitle: $0.scheduledAt == nil ? "RawTask · 아직 배치 전" : "RawTask · \(shortDate($0.scheduledAt))",
                    detail: "Plan에서 WorkBlock으로 배치할 수 있습니다.",
                    syncText: $0.syncState.title,
                    date: $0.scheduledAt ?? $0.createdAt
                )
            }

        let blockItems = projectBlocks
            .filter { $0.executionState == .planned && $0.id != currentFocusBlock?.id }
            .map { queueItem(for: $0, kind: .next, detail: "가까운 예정 WorkBlock입니다.") }

        return (taskItems + blockItems).sorted { $0.date < $1.date }
    }

    private var waitingQueueItems: [ProjectDashboardQueueItem] {
        let now = Date()
        let waitingTasks = projectTasks
            .filter { ($0.scheduledAt ?? .distantPast) > now }
            .map {
                ProjectDashboardQueueItem(
                    kind: .waiting,
                    source: .rawTask,
                    sourceId: $0.id,
                    rawTaskId: $0.id,
                    blockId: nil,
                    title: $0.title,
                    subtitle: "대기 중 · \(shortDate($0.scheduledAt))",
                    detail: "예약된 날짜 이후 Next로 돌아옵니다.",
                    syncText: $0.syncState.title,
                    date: $0.scheduledAt ?? $0.createdAt
                )
            }

        let delayedBlocks = projectBlocks
            .filter { $0.executionState == .delayed }
            .map { queueItem(for: $0, kind: .waiting, detail: "미룸 처리된 WorkBlock입니다.") }

        return (waitingTasks + delayedBlocks).sorted { $0.date < $1.date }
    }

    private var reviewQueueItems: [ProjectDashboardQueueItem] {
        projectBlocks
            .filter { $0.executionState == .completed && !hasLog(for: $0) }
            .map { queueItem(for: $0, kind: .review, detail: "완료됐지만 아직 회고 Log가 없습니다.") }
            .sorted { $0.date > $1.date }
    }

    private var doneQueueItems: [ProjectDashboardQueueItem] {
        projectBlocks
            .filter { $0.executionState == .completed && hasLog(for: $0) }
            .map { queueItem(for: $0, kind: .done, detail: "회고까지 연결된 완료 항목입니다.") }
            .sorted { $0.date > $1.date }
    }

    private var queueCounts: [ProjectDashboardQueueKind: Int] {
        [
            .next: nextQueueItems.count,
            .waiting: waitingQueueItems.count,
            .review: reviewQueueItems.count,
            .done: doneQueueItems.count
        ]
    }

    private var projectBriefSections: [ProjectMemoSection] {
        Array(projectSections.prefix(4))
    }

    private var trackerSummary: ProjectDashboardTrackerSummary {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentBlocks = projectBlocks.filter { $0.startAt >= weekAgo }
        let recentLogs = projectLogs.filter { $0.createdAt >= weekAgo }
        let completed = recentBlocks.filter { $0.executionState == .completed }.count
        let actionable = max(1, recentBlocks.filter { $0.executionState != .stopped }.count)
        let minutes = recentBlocks.reduce(0) { total, block in
            total + max(0, Int(block.endAt.timeIntervalSince(block.startAt) / 60))
        }

        return ProjectDashboardTrackerSummary(
            activity: activityDots(days: 7),
            weeklyMinutes: minutes,
            completedBlocks: completed,
            planDoneRatio: Double(completed) / Double(actionable),
            logCount: recentLogs.count,
            recentActivity: latestActivityText,
            topMood: topTag(recentLogs.flatMap { $0.moodTags }),
            topBlocker: topTag(recentLogs.flatMap { $0.blockerTags })
        )
    }

    private var attentionItems: [ProjectDashboardAttentionItem] {
        var items: [ProjectDashboardAttentionItem] = []

        if projectArea == nil {
            items.append(.init(title: "Area 미지정", detail: "Project가 아직 Area에 연결되어 있지 않습니다.", priority: .high, symbolName: "folder.badge.questionmark"))
        }

        if projectArea?.syncState == .failed || project.syncState == .failed {
            items.append(.init(title: "Sync 확인 필요", detail: "Area Calendar 또는 Reminder 연결 상태를 Settings에서 확인하세요.", priority: .high, symbolName: "exclamationmark.arrow.triangle.2.circlepath"))
        }

        let unresolved = todayBlocks.filter { $0.endAt < Date() && ($0.executionState == .planned || $0.executionState == .inProgress) }
        if !unresolved.isEmpty {
            items.append(.init(title: "상태 미결정 WorkBlock", detail: "\(unresolved.count)개 블록의 완료 / 미룸 / 중단 선택이 필요합니다.", priority: .medium, symbolName: "clock.badge.exclamationmark"))
        }

        if reviewQueueItems.count >= 3 {
            items.append(.init(title: "Review 적체", detail: "회고가 필요한 완료 항목이 \(reviewQueueItems.count)개 남아 있습니다.", priority: .medium, symbolName: "text.bubble"))
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        if project.status == .active && projectBlocks.filter({ $0.startAt > sevenDaysAgo }).isEmpty {
            items.append(.init(title: "최근 활동 없음", detail: "Active 상태지만 최근 7일간 WorkBlock이 없습니다.", priority: .low, symbolName: "pause.circle"))
        }

        if project.goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append(.init(title: "Goal 비어 있음", detail: "Project Brief에 목표를 짧게 남겨두면 다음 행동이 선명해집니다.", priority: .low, symbolName: "target"))
        }

        return items
    }

    private var compactInsight: String {
        if reviewQueueItems.count >= 2 {
            return "완료된 작업이 Review에 머물고 있습니다. 짧은 Log 하나가 Done 흐름을 닫습니다."
        }
        if waitingQueueItems.count >= 3 {
            return "Waiting 항목이 늘고 있습니다. 외부 대기인지 에너지 문제인지 분리해보세요."
        }
        if trackerSummary.planDoneRatio >= 0.7 && trackerSummary.completedBlocks > 0 {
            return "이번 주 완료율이 안정적입니다. 같은 블록 길이를 유지해도 좋습니다."
        }
        return "다음 실행 블록 하나와 짧은 회고 하나가 이 프로젝트의 흐름을 선명하게 만듭니다."
    }

    private var lastActivityText: String {
        latestActivityText
    }

    private var latestActivityText: String {
        let latestBlock = projectBlocks.map(\.updatedAt).max()
        let latestLog = projectLogs.map(\.updatedAt).max()
        let latestNote = projectNotes.map(\.updatedAt).max()
        let latest = [latestBlock, latestLog, latestNote, project.updatedAt].compactMap { $0 }.max() ?? project.updatedAt
        return latest.formatted(date: .abbreviated, time: .shortened)
    }

    private func queueItems(for kind: ProjectDashboardQueueKind) -> [ProjectDashboardQueueItem] {
        switch kind {
        case .next: return nextQueueItems
        case .waiting: return waitingQueueItems
        case .review: return reviewQueueItems
        case .done: return doneQueueItems
        }
    }

    private func queueItem(for block: WorkBlock, kind: ProjectDashboardQueueKind, detail: String) -> ProjectDashboardQueueItem {
        ProjectDashboardQueueItem(
            kind: kind,
            source: .workBlock,
            sourceId: block.id,
            rawTaskId: block.rawTaskId,
            blockId: block.id,
            title: block.title,
            subtitle: "\(block.executionState.title) · \(block.startAt.formatted(date: .abbreviated, time: .shortened))",
            detail: detail,
            syncText: block.syncState.title,
            date: block.startAt
        )
    }

    private func hasLog(for block: WorkBlock) -> Bool {
        projectLogs.contains { $0.workBlockId == block.id }
    }

    private func remainingText(for block: WorkBlock) -> String? {
        let now = Date()
        if block.endAt <= now { return "종료 시간 지남" }
        if block.startAt > now {
            let minutes = max(0, Int(block.startAt.timeIntervalSince(now) / 60))
            return "\(minutes)분 후 시작"
        }
        let minutes = max(0, Int(block.endAt.timeIntervalSince(now) / 60))
        return "\(minutes)분 남음"
    }

    private func activityDots(days: Int) -> [Bool] {
        (0..<days).reversed().map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            return projectBlocks.contains { Calendar.current.isDate($0.startAt, inSameDayAs: date) } ||
                projectLogs.contains { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
        }
    }

    private func topTag(_ tags: [String]) -> String? {
        let counts = Dictionary(grouping: tags, by: { $0 }).mapValues { $0.count }
        return counts.max { $0.value < $1.value }?.key
    }

    private func shortDate(_ date: Date?) -> String {
        guard let date else { return "날짜 없음" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func startCurrentFocus() {
        guard let block = currentFocusBlock else { return }
        try? stores.workBlockStore.start(block: block)
    }

    private func completeCurrentFocus() {
        guard let block = currentFocusBlock else { return }
        try? stores.workBlockStore.markCompleted(block: block)
        logTargetWorkBlockId = block.id
        showingLogEditor = true
    }

    private func delayCurrentFocus() {
        guard let block = currentFocusBlock else { return }
        _ = try? stores.workBlockStore.markDelayed(block: block)
    }

    private func stopCurrentFocus() {
        guard let block = currentFocusBlock else { return }
        try? stores.workBlockStore.markStopped(block: block)
    }

    private func openCurrentFocusInPlan() {
        if let block = currentFocusBlock {
            sharedSelectedDate = block.startAt.timeIntervalSince1970
        } else {
            openTodayInPlan()
        }
    }

    private func openTodayInPlan() {
        sharedSelectedDate = Date().timeIntervalSince1970
    }

    private func openQueueItemInPlan(_ item: ProjectDashboardQueueItem) {
        sharedSelectedDate = item.date.timeIntervalSince1970
    }

    private func openLogForQueueItem(_ item: ProjectDashboardQueueItem) {
        logTargetWorkBlockId = item.blockId
        showingLogEditor = true
    }

    private func openProjectLog() {
        logTargetWorkBlockId = nil
        showingLogEditor = true
    }

    private func addMissingTemplateSections() {
        for section in TemplateDatabase.sections(for: project.type) {
            let exists = projectSections.contains {
                $0.title.localizedCaseInsensitiveCompare(section.title) == .orderedSame
            }
            if !exists {
                try? stores.projectStore.addMemoSection(projectId: project.id, title: section.title, content: section.content)
            }
        }
    }

    private func changeStatus(_ status: ProjectStatus) {
        try? stores.projectStore.updateProjectStatus(project: project, status: status)
    }
}
