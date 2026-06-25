import Foundation
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var stores: AppStores

    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \ProjectArea.updatedAt, order: .reverse) private var areas: [ProjectArea]
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]

    @AppStorage("nouae.sharedSelectedDate") private var sharedSelectedDateTime: Double = Date().timeIntervalSinceReferenceDate

    @State private var selectedQueue: DashboardQueueKind = .next
    @State private var message: String?
    @State private var showingSettings = false
    @State private var logBlock: WorkBlock?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                AppScreenContainer(spacing: AppUI.Spacing.section) {
                    MissionControlMVPHeader(
                        briefing: missionBriefing,
                        syncText: globalSyncSummary.text,
                        syncTone: globalSyncSummary.tone,
                        onSettings: { showingSettings = true }
                    )

                    #if DEBUG
                    Text("MissionControlMVPLayout ACTIVE L16")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue, in: Capsule())
                    #endif

                    if geometry.size.width >= 900 {
                        wideLayout(width: geometry.size.width)
                    } else {
                        compactLayout
                    }

                    #if DEBUG
                    sampleDataPanel
                    #endif
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $logBlock) { block in
                LogEditorSheet(initialProjectId: block.projectId, initialWorkBlockId: block.id)
            }
        }
    }

    private func wideLayout(width: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                currentFocusPanel
                operationalQueuePanel
                todayTimelinePanel
            }
            .frame(width: max(520, width * 0.66), alignment: .topLeading)

            VStack(alignment: .leading, spacing: 16) {
                activeProjectsPanel
                attentionPanel
                nextAdjustmentPanel
                trackerPanel
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 16) {
            currentFocusPanel
            operationalQueuePanel
            todayTimelinePanel
            activeProjectsPanel
            attentionPanel
            nextAdjustmentPanel
            trackerPanel
        }
    }

    private var currentFocusPanel: some View {
        CurrentFocusPanel(
            block: currentFocusBlock,
            fallback: selectedQueueItems.first,
            projectTitle: projectTitle(currentFocusBlock?.projectId),
            colorHex: projectColorHex(currentFocusBlock?.projectId),
            onStart: start,
            onComplete: complete,
            onDelay: delay,
            onStop: stop,
            onOpenPlan: openCurrentFocusInPlan
        )
    }

    private var operationalQueuePanel: some View {
        OperationalQueuePanel(
            selection: $selectedQueue,
            counts: dashboardQueueCounts,
            items: selectedQueueItems,
            onAction: handleQueueAction
        )
    }

    private var todayTimelinePanel: some View {
        TodayTimelinePanel(
            blocks: todayTimeline,
            projectTitle: projectTitle,
            colorHex: projectColorHex
        )
    }

    private var activeProjectsPanel: some View {
        ActiveProjectsCompactPanel(
            projects: activeProjects,
            areaTitle: areaTitle,
            todayBlockCount: todayBlockCount,
            nextTaskTitle: nextTaskTitle,
            progress: projectProgress
        )
    }

    private var attentionPanel: some View {
        AttentionPanel(items: attentionItems) {
            showingSettings = true
        }
    }

    private var nextAdjustmentPanel: some View {
        NextAdjustmentCompactPanel(
            adjustments: activeAdjustments,
            projectTitle: projectTitle
        )
    }

    private var trackerPanel: some View {
        CompactTrackerSummaryPanel(summary: compactTrackerSummary)
    }

    private var selectedQueueItems: [DashboardQueueItem] {
        switch selectedQueue {
        case .next: return nextItems()
        case .waiting: return waitingItems()
        case .review: return reviewItems()
        case .done: return doneItems()
        }
    }

    private var dashboardQueueCounts: [DashboardQueueKind: Int] {
        [
            .next: nextItems().count,
            .waiting: waitingItems().count,
            .review: reviewItems().count,
            .done: doneItems().count
        ]
    }

    private var missionBriefing: String {
        let nextCount = nextItems().count
        let reviewCount = reviewItems().count
        if let focus = currentFocusBlock {
            let projectText = projectTitle(focus.projectId) ?? "Project 없음"
            return "현재 \(projectText)가 움직이고 있으며 다음 기준점은 \(focus.title)입니다."
        }
        if nextCount > 0 || reviewCount > 0 {
            return "다음 작업 \(nextCount)개, 회고할 작업 \(reviewCount)개가 있습니다."
        }
        return "오늘은 조용합니다. Plan에서 다음 실행 단위를 하나 배치해도 좋습니다."
    }

    private var globalSyncSummary: (text: String, tone: StatusBadge.Tone) {
        let failed = projects.filter { $0.syncState == .failed }.count
            + areas.filter { $0.syncState == .failed }.count
            + tasks.filter { $0.syncState == .failed }.count
            + blocks.filter { $0.syncState == .failed }.count
        let pending = tasks.filter { $0.syncState == .pending || $0.syncState == .syncing }.count
            + blocks.filter { $0.syncState == .pending || $0.syncState == .syncing }.count
        if failed > 0 {
            return ("Sync attention \(failed)", .orange)
        }
        if pending > 0 {
            return ("Sync pending \(pending)", .blue)
        }
        return ("Sync stable", .green)
    }

    private var currentFocusBlock: WorkBlock? {
        let inProgressToday = todayTimeline.first { $0.executionState == .inProgress }
        if let inProgressToday {
            return inProgressToday
        }
        let inProgress = blocks
            .filter { $0.executionState == .inProgress }
            .sorted { $0.startAt < $1.startAt }
            .first
        if let inProgress {
            return inProgress
        }
        return nearestTodayPlannedBlock
    }

    private var nearestTodayPlannedBlock: WorkBlock? {
        let now = Date()
        return todayTimeline
            .filter { $0.executionState == .planned }
            .sorted { abs($0.startAt.timeIntervalSince(now)) < abs($1.startAt.timeIntervalSince(now)) }
            .first
    }

    private var todayTimeline: [WorkBlock] {
        blocks
            .filter { Calendar.current.isDate($0.startAt, inSameDayAs: Date()) }
            .sorted { $0.startAt < $1.startAt }
    }

    private var activeProjects: [Project] {
        projects
            .filter { $0.status == .active && $0.archivedAt == nil }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var activeAdjustments: [NextAdjustment] {
        adjustments
            .filter { $0.isActive }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func nextItems(projectId: UUID? = nil) -> [DashboardQueueItem] {
        let now = Date()
        let focusBlockId = currentFocusBlock?.id
        let rawItems = tasks
            .filter { task in
                guard !task.isConvertedToBlock else { return false }
                if let projectId, task.projectId != projectId { return false }
                if let scheduledAt = task.scheduledAt, scheduledAt > now { return false }
                return true
            }
            .map { task in queueItem(for: task, kind: .next, actionTitle: "Plan", action: .plan) }

        let blockItems = blocks
            .filter { block in
                if let projectId, block.projectId != projectId { return false }
                guard block.executionState == .planned else { return false }
                return block.id != focusBlockId
            }
            .sorted { $0.startAt < $1.startAt }
            .map { block in queueItem(for: block, kind: .next, actionTitle: "Start", action: .start) }

        var values = rawItems
        values.append(contentsOf: blockItems)
        return values
    }

    private func waitingItems(projectId: UUID? = nil) -> [DashboardQueueItem] {
        let now = Date()
        let rawItems = tasks
            .filter { task in
                guard !task.isConvertedToBlock else { return false }
                if let projectId, task.projectId != projectId { return false }
                guard let scheduledAt = task.scheduledAt else { return false }
                return scheduledAt > now
            }
            .map { task in queueItem(for: task, kind: .waiting, actionTitle: "Next", action: .plan) }

        let delayedBlocks = blocks
            .filter { block in
                if let projectId, block.projectId != projectId { return false }
                return block.executionState == .delayed
            }
            .map { block in queueItem(for: block, kind: .waiting, actionTitle: "Open", action: .plan) }

        var values = rawItems
        values.append(contentsOf: delayedBlocks)
        return values
    }

    private func reviewItems(projectId: UUID? = nil) -> [DashboardQueueItem] {
        blocks
            .filter { block in
                if let projectId, block.projectId != projectId { return false }
                guard block.executionState == .completed else { return false }
                return !hasLog(for: block)
            }
            .sorted { $0.endAt > $1.endAt }
            .map { block in queueItem(for: block, kind: .review, actionTitle: "Log", action: .writeLog) }
    }

    private func doneItems(projectId: UUID? = nil, dateRange: DateInterval? = nil) -> [DashboardQueueItem] {
        let range = dateRange ?? todayRange
        return blocks
            .filter { block in
                if let projectId, block.projectId != projectId { return false }
                guard block.executionState == .completed else { return false }
                guard block.endAt >= range.start && block.endAt < range.end else { return false }
                return hasLog(for: block)
            }
            .sorted { $0.endAt > $1.endAt }
            .map { block in queueItem(for: block, kind: .done, actionTitle: "Detail", action: .markReviewed) }
    }

    private var attentionItems: [DashboardAttentionItem] {
        var values: [DashboardAttentionItem] = []
        let failedSync = projects.filter { $0.syncState == .failed }.count
            + areas.filter { $0.syncState == .failed }.count
            + tasks.filter { $0.syncState == .failed }.count
            + blocks.filter { $0.syncState == .failed }.count
        if failedSync > 0 {
            values.append(.init(title: "Sync attention", message: "\(failedSync)개 항목의 Calendar 또는 Reminder sync를 확인해야 합니다.", tone: .orange, actionTitle: "Settings"))
        }

        let unresolved = blocks.filter { block in
            block.endAt < Date() && (block.executionState == .planned || block.executionState == .inProgress)
        }.count
        if unresolved > 0 {
            values.append(.init(title: "상태 미결정 WorkBlock", message: "종료 시간이 지난 \(unresolved)개 블록의 완료 / 미룸 / 중단을 선택하세요.", tone: .orange, actionTitle: nil))
        }

        let staleWaiting = tasks.filter { task in
            guard let scheduledAt = task.scheduledAt else { return false }
            return !task.isConvertedToBlock && scheduledAt < Calendar.current.startOfDay(for: Date())
        }.count
        if staleWaiting > 0 {
            values.append(.init(title: "오래된 Waiting", message: "\(staleWaiting)개 RawTask의 대기 날짜가 지났습니다.", tone: .neutral, actionTitle: nil))
        }

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let staleProjects = activeProjects.filter { project in
            !blocks.contains { $0.projectId == project.id && $0.startAt >= weekAgo }
        }.count
        if staleProjects > 0 {
            values.append(.init(title: "정체된 Active Project", message: "\(staleProjects)개 active project에 최근 7일간 WorkBlock이 없습니다.", tone: .neutral, actionTitle: nil))
        }

        return values
    }

    private var compactTrackerSummary: DashboardTrackerSummary {
        let week = weekRange
        let weekBlocks = blocks.filter { $0.startAt >= week.start && $0.startAt < week.end }
        let completed = weekBlocks.filter { $0.executionState == .completed }
        let totalMinutes = completed.reduce(0) { partial, block in
            partial + max(0, Int(block.endAt.timeIntervalSince(block.startAt) / 60))
        }
        let denominator = max(1, weekBlocks.count)
        let completionRate = Int((Double(completed.count) / Double(denominator)) * 100)
        return DashboardTrackerSummary(
            activity: activityDots(days: 7),
            completedThisWeek: completed.count,
            workMinutesThisWeek: totalMinutes,
            logStreak: logStreak,
            completionRate: completionRate
        )
    }

    private func queueItem(for task: RawTask, kind: DashboardQueueKind, actionTitle: String, action: DashboardQueueAction) -> DashboardQueueItem {
        DashboardQueueItem(
            id: "task-\(task.id.uuidString)-\(kind.rawValue)",
            kind: kind,
            title: task.title,
            subtitle: taskSubtitle(task),
            projectTitle: projectTitle(task.projectId),
            colorHex: projectColorHex(task.projectId),
            syncState: task.syncState,
            rawTaskId: task.id,
            workBlockId: nil,
            projectId: task.projectId,
            primaryActionTitle: actionTitle,
            primaryAction: action
        )
    }

    private func queueItem(for block: WorkBlock, kind: DashboardQueueKind, actionTitle: String, action: DashboardQueueAction) -> DashboardQueueItem {
        DashboardQueueItem(
            id: "block-\(block.id.uuidString)-\(kind.rawValue)",
            kind: kind,
            title: block.title,
            subtitle: blockSubtitle(block),
            projectTitle: projectTitle(block.projectId),
            colorHex: projectColorHex(block.projectId),
            syncState: block.syncState,
            rawTaskId: block.rawTaskId,
            workBlockId: block.id,
            projectId: block.projectId,
            primaryActionTitle: actionTitle,
            primaryAction: action
        )
    }

    private func handleQueueAction(_ action: DashboardQueueAction, item: DashboardQueueItem) {
        switch action {
        case .plan:
            if let rawTaskId = item.rawTaskId,
               let task = tasks.first(where: { $0.id == rawTaskId }) {
                sharedSelectedDateTime = Calendar.current.startOfDay(for: task.scheduledAt ?? Date()).timeIntervalSinceReferenceDate
                message = "Plan 탭에서 \(task.title)을 배치하세요."
            } else if let block = block(for: item) {
                sharedSelectedDateTime = Calendar.current.startOfDay(for: block.startAt).timeIntervalSinceReferenceDate
                message = "Plan 탭에서 \(block.title)을 확인하세요."
            }
        case .start:
            if let block = block(for: item) { start(block) }
        case .complete:
            if let block = block(for: item) { complete(block) }
        case .delay:
            if let block = block(for: item) { delay(block) }
        case .stop:
            if let block = block(for: item) { stop(block) }
        case .writeLog:
            if let block = block(for: item) { logBlock = block }
        case .markReviewed:
            message = "이미 오늘 Done에 반영된 항목입니다."
        case .reopen:
            message = "다시 열기는 후속 단계에서 지원합니다."
        }
    }

    private func start(_ block: WorkBlock) {
        do {
            try stores.workBlockStore.start(block: block)
            message = "\(block.title)을 시작했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func complete(_ block: WorkBlock) {
        do {
            try stores.workBlockStore.markCompleted(block: block)
            logBlock = block
            message = "\(block.title)을 완료했습니다. 짧은 Log를 남겨 Review를 닫을 수 있습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func delay(_ block: WorkBlock) {
        do {
            _ = try stores.workBlockStore.markDelayed(block: block)
            message = "\(block.title)을 미뤘습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func stop(_ block: WorkBlock) {
        do {
            try stores.workBlockStore.markStopped(block: block)
            message = "\(block.title)을 중단 처리했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func openCurrentFocusInPlan() {
        if let block = currentFocusBlock {
            sharedSelectedDateTime = Calendar.current.startOfDay(for: block.startAt).timeIntervalSinceReferenceDate
            message = "Plan 탭에서 \(block.title)을 확인하세요."
        } else {
            sharedSelectedDateTime = Calendar.current.startOfDay(for: Date()).timeIntervalSinceReferenceDate
            message = "Plan 탭에서 다음 항목을 배치하세요."
        }
    }

    private func block(for item: DashboardQueueItem) -> WorkBlock? {
        guard let id = item.workBlockId else { return nil }
        return blocks.first { $0.id == id }
    }

    private func hasLog(for block: WorkBlock) -> Bool {
        logs.contains { $0.workBlockId == block.id }
    }

    private func taskSubtitle(_ task: RawTask) -> String {
        if let scheduledAt = task.scheduledAt {
            return scheduledAt > Date()
                ? "Waiting until \(scheduledAt.formatted(date: .abbreviated, time: .shortened))"
                : "Ready since \(scheduledAt.formatted(date: .abbreviated, time: .shortened))"
        }
        return "RawTask"
    }

    private func blockSubtitle(_ block: WorkBlock) -> String {
        "\(block.startAt.formatted(date: .abbreviated, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))"
    }

    private func projectTitle(_ id: UUID?) -> String? {
        guard let id else { return nil }
        return projects.first { $0.id == id }?.title
    }

    private func projectColorHex(_ id: UUID?) -> String? {
        guard let id else { return nil }
        return projects.first { $0.id == id }?.calendarColorHex
    }

    private func areaTitle(_ id: UUID?) -> String? {
        guard let id else { return nil }
        return areas.first { $0.id == id }?.title
    }

    private func todayBlockCount(projectId: UUID) -> Int {
        todayTimeline.filter { $0.projectId == projectId }.count
    }

    private func nextTaskTitle(projectId: UUID) -> String? {
        tasks
            .filter { $0.projectId == projectId && !$0.isConvertedToBlock }
            .sorted { $0.createdAt < $1.createdAt }
            .first?
            .title
    }

    private func projectProgress(projectId: UUID) -> Double {
        let scoped = blocks.filter { $0.projectId == projectId }
        guard !scoped.isEmpty else { return 0 }
        let completed = scoped.filter { $0.executionState == .completed }.count
        return Double(completed) / Double(scoped.count)
    }

    private func activityDots(days: Int) -> [Bool] {
        (0..<days).reversed().map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            return blocks.contains { Calendar.current.isDate($0.startAt, inSameDayAs: date) }
                || logs.contains { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
        }
    }

    private var logStreak: Int {
        var streak = 0
        for offset in 0..<14 {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            if logs.contains(where: { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private var todayRange: DateInterval {
        Calendar.current.dateInterval(of: .day, for: Date()) ?? DateInterval(start: Date(), duration: 86400)
    }

    private var weekRange: DateInterval {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date()) ?? DateInterval(start: Date(), duration: 86400 * 7)
    }

    private var sampleDataPanel: some View {
        AppPanel(title: "Development Data", subtitle: "Swift Playgrounds 테스트용") {
            HStack {
                Button("샘플 데이터 생성", action: seed)
                Button("샘플 데이터 제거", role: .destructive, action: removeSampleData)
            }
            if let message {
                AppDivider()
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func seed() {
        do {
            try SampleDataSeeder.seed(context: context, stores: stores)
            message = "샘플 데이터를 확인했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func removeSampleData() {
        do {
            try SampleDataSeeder.removeSampleData(context: context)
            message = "샘플 데이터를 제거했습니다."
        } catch {
            message = error.localizedDescription
        }
    }
}
