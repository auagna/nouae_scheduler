import SwiftUI

enum DashboardQueueKind: String, CaseIterable, Identifiable {
    case next = "Next"
    case waiting = "Waiting"
    case review = "Review"
    case done = "Done"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .next: return "arrow.forward.circle"
        case .waiting: return "clock"
        case .review: return "text.magnifyingglass"
        case .done: return "checkmark.circle"
        }
    }
}

enum DashboardQueueAction {
    case plan
    case start
    case complete
    case delay
    case stop
    case writeLog
    case markReviewed
    case reopen
}

struct DashboardQueueItem: Identifiable {
    let id: String
    let kind: DashboardQueueKind
    let title: String
    let subtitle: String
    let projectTitle: String?
    let colorHex: String?
    let syncState: SyncState
    let rawTaskId: UUID?
    let workBlockId: UUID?
    let projectId: UUID?
    let primaryActionTitle: String
    let primaryAction: DashboardQueueAction
}

struct DashboardAttentionItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let tone: StatusBadge.Tone
    let actionTitle: String?
}

struct DashboardTrackerSummary {
    let activity: [Bool]
    let completedThisWeek: Int
    let workMinutesThisWeek: Int
    let logStreak: Int
    let completionRate: Int
}

struct MissionControlMVPHeader: View {
    let briefing: String
    let syncText: String
    let syncTone: StatusBadge.Tone
    let onSettings: () -> Void

    var body: some View {
        AppPageHeader(title: "Mission Control", subtitle: briefing) {
            HStack(spacing: 8) {
                StatusBadge(syncText, tone: syncTone, symbolName: syncSymbolName)
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Settings")
            }
        }
    }

    private var syncSymbolName: String {
        switch syncTone {
        case .green: return "checkmark.icloud"
        case .orange, .red: return "exclamationmark.icloud"
        default: return "icloud"
        }
    }
}

struct CurrentFocusPanel: View {
    let block: WorkBlock?
    let fallback: DashboardQueueItem?
    let projectTitle: String?
    let colorHex: String?
    let onStart: (WorkBlock) -> Void
    let onComplete: (WorkBlock) -> Void
    let onDelay: (WorkBlock) -> Void
    let onStop: (WorkBlock) -> Void
    let onOpenPlan: () -> Void

    var body: some View {
        AppPanel(title: "Current Focus", subtitle: "지금 가장 먼저 볼 실행 단위") {
            if let block {
                focusBlock(block)
            } else {
                emptyFocus
            }
        }
    }

    private func focusBlock(_ block: WorkBlock) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(calendarHex: colorHex))
                    .frame(width: 5)
                VStack(alignment: .leading, spacing: 6) {
                    Text(block.title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)
                    Text(timeRange(block.startAt, block.endAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let projectTitle {
                        StatusBadge(projectTitle, tone: .purple, symbolName: "folder")
                    }
                    if !block.memo.isEmpty {
                        Text(block.memo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    StatusBadge(block.executionState.title, tone: tone(for: block.executionState))
                    StatusBadge(block.syncState.title, tone: block.syncState == .failed ? .orange : .neutral, symbolName: "icloud")
                }
            }

            HStack(spacing: 8) {
                Button("Start") { onStart(block) }
                    .disabled(block.executionState == .inProgress || block.executionState == .completed)
                Button("Complete") { onComplete(block) }
                Button("Delay") { onDelay(block) }
                Button("Stop") { onStop(block) }
                Spacer()
                Button("Open in Plan", action: onOpenPlan)
            }
            .buttonStyle(.bordered)
            .font(.caption.weight(.semibold))
        }
    }

    private var emptyFocus: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("현재 실행 중인 작업이 없습니다.")
                .font(.subheadline.weight(.semibold))
            if let fallback {
                Text("다음 제안: \(fallback.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(fallback.primaryActionTitle, action: onOpenPlan)
                    .buttonStyle(.borderedProminent)
            } else {
                Text("RawTask를 만들거나 Plan에서 WorkBlock을 배치하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tone(for state: WorkBlockState) -> StatusBadge.Tone {
        switch state {
        case .planned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .delayed: return .neutral
        case .stopped: return .red
        }
    }

    private func timeRange(_ startAt: Date, _ endAt: Date) -> String {
        "\(startAt.formatted(date: .omitted, time: .shortened)) - \(endAt.formatted(date: .omitted, time: .shortened))"
    }
}

struct OperationalQueuePanel: View {
    @Binding var selection: DashboardQueueKind
    let counts: [DashboardQueueKind: Int]
    let items: [DashboardQueueItem]
    let onAction: (DashboardQueueAction, DashboardQueueItem) -> Void

    var body: some View {
        AppPanel(title: "Operational Queue", subtitle: "Dashboard는 저장 상태가 아니라 현재 행동 큐를 계산합니다.") {
            VStack(alignment: .leading, spacing: 12) {
                DashboardQueueCountStrip(selection: $selection, counts: counts)

                if items.isEmpty {
                    DashboardEmptyState(title: "\(selection.rawValue) 항목이 없습니다.", message: emptyMessage)
                } else {
                    ForEach(items) { item in
                        OperationalQueueRow(item: item) { action in
                            onAction(action, item)
                        }
                    }
                }
            }
        }
    }

    private var emptyMessage: String {
        switch selection {
        case .next: return "지금 실행 가능한 RawTask나 예정 WorkBlock이 없습니다."
        case .waiting: return "대기 중인 항목이 없습니다."
        case .review: return "회고가 필요한 완료 항목이 없습니다."
        case .done: return "오늘 완료된 항목이 아직 없습니다."
        }
    }
}

struct DashboardQueueCountStrip: View {
    @Binding var selection: DashboardQueueKind
    let counts: [DashboardQueueKind: Int]

    var body: some View {
        Picker("Queue", selection: $selection) {
            ForEach(DashboardQueueKind.allCases) { kind in
                Text("\(kind.rawValue) \(counts[kind, default: 0])").tag(kind)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct OperationalQueueRow: View {
    let item: DashboardQueueItem
    let onAction: (DashboardQueueAction) -> Void

    var body: some View {
        AppListRow(title: item.title, subtitle: subtitle) {
            Image(systemName: item.kind.symbolName)
                .foregroundStyle(Color(calendarHex: item.colorHex))
        } trailing: {
            HStack(spacing: 7) {
                if item.syncState == .failed {
                    StatusBadge("Sync", tone: .orange, symbolName: "exclamationmark.icloud")
                }
                Button(item.primaryActionTitle) {
                    onAction(item.primaryAction)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var subtitle: String {
        var values = [item.subtitle]
        if let projectTitle = item.projectTitle {
            values.append(projectTitle)
        }
        return values.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

struct TodayTimelinePanel: View {
    let blocks: [WorkBlock]
    let projectTitle: (UUID?) -> String?
    let colorHex: (UUID?) -> String?

    var body: some View {
        AppPanel(title: "Today Timeline", subtitle: "Plan HourGrid를 복제하지 않는 compact timeline") {
            if blocks.isEmpty {
                DashboardEmptyState(title: "오늘 배치된 WorkBlock이 없습니다.", message: "Plan에서 RawTask를 시간 위에 올려보세요.")
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    currentTimeIndicator
                    ForEach(blocks) { block in
                        AppListRow(title: block.title, subtitle: timelineSubtitle(for: block)) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color(calendarHex: colorHex(block.projectId)))
                                .frame(width: 5, height: 28)
                        } trailing: {
                            StatusBadge(block.executionState.title, tone: tone(for: block.executionState))
                        }
                    }
                }
            }
        }
    }

    private var currentTimeIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red.opacity(0.78))
                .frame(width: 7, height: 7)
            Text("Now \(Date().formatted(date: .omitted, time: .shortened))")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 6)
    }

    private func timelineSubtitle(for block: WorkBlock) -> String {
        var values = [timeRange(block.startAt, block.endAt)]
        if let title = projectTitle(block.projectId) {
            values.append(title)
        }
        return values.joined(separator: " · ")
    }

    private func tone(for state: WorkBlockState) -> StatusBadge.Tone {
        switch state {
        case .planned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .delayed: return .neutral
        case .stopped: return .red
        }
    }

    private func timeRange(_ startAt: Date, _ endAt: Date) -> String {
        "\(startAt.formatted(date: .omitted, time: .shortened)) - \(endAt.formatted(date: .omitted, time: .shortened))"
    }
}

struct ActiveProjectsCompactPanel: View {
    let projects: [Project]
    let areaTitle: (UUID?) -> String?
    let todayBlockCount: (UUID) -> Int
    let nextTaskTitle: (UUID) -> String?
    let progress: (UUID) -> Double

    var body: some View {
        AppPanel(title: "Active Projects", subtitle: "움직이는 프로젝트만 표시합니다.") {
            if projects.isEmpty {
                DashboardEmptyState(title: "Active Project가 없습니다.", message: "Projects 탭에서 움직일 프로젝트를 active로 바꾸세요.")
            } else {
                ForEach(projects.prefix(5)) { project in
                    NavigationLink {
                        ProjectDashboardView(project: project)
                    } label: {
                        AppCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(Color(calendarHex: project.calendarColorHex))
                                        .frame(width: 9, height: 9)
                                    Text(project.title)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    StatusBadge(project.status.title, tone: .blue)
                                }
                                ProgressView(value: progress(project.id))
                                Text(projectSubtitle(project))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func projectSubtitle(_ project: Project) -> String {
        var values: [String] = []
        if let area = areaTitle(project.areaId) {
            values.append(area)
        }
        values.append("Today \(todayBlockCount(project.id))")
        if let next = nextTaskTitle(project.id) {
            values.append("Next \(next)")
        }
        return values.joined(separator: " · ")
    }
}

struct AttentionPanel: View {
    let items: [DashboardAttentionItem]
    let onOpenSettings: () -> Void

    var body: some View {
        AppPanel(title: "Attention", subtitle: "확인이 필요한 항목") {
            if items.isEmpty {
                DashboardEmptyState(title: "주의 항목이 없습니다.", message: "Sync와 실행 상태가 안정적입니다.")
            } else {
                ForEach(items.prefix(6)) { item in
                    AppListRow(title: item.title, subtitle: item.message) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(item.tone.color)
                    } trailing: {
                        if let actionTitle = item.actionTitle {
                            Button(actionTitle, action: onOpenSettings)
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
    }
}

struct NextAdjustmentCompactPanel: View {
    let adjustments: [NextAdjustment]
    let projectTitle: (UUID?) -> String?

    var body: some View {
        AppPanel(title: "Next Adjustment", subtitle: "최근 active 조정") {
            if adjustments.isEmpty {
                DashboardEmptyState(title: "활성 조정이 없습니다.", message: "Log에서 다음 조정을 남기면 여기에 표시됩니다.")
            } else {
                ForEach(adjustments.prefix(3)) { adjustment in
                    AppListRow(title: adjustment.content, subtitle: subtitle(for: adjustment)) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.blue)
                    } trailing: {
                        StatusBadge("Active", tone: .blue)
                    }
                }
            }
        }
    }

    private func subtitle(for adjustment: NextAdjustment) -> String {
        var values: [String] = []
        if let project = projectTitle(adjustment.projectId) {
            values.append(project)
        }
        values.append(adjustment.createdAt.formatted(date: .abbreviated, time: .omitted))
        return values.joined(separator: " · ")
    }
}

struct CompactTrackerSummaryPanel: View {
    let summary: DashboardTrackerSummary

    var body: some View {
        AppPanel(title: "Tracker Summary", subtitle: "MVP compact tracker") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(Array(summary.activity.enumerated()), id: \.offset) { _, active in
                        Circle()
                            .fill(active ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
                            .frame(width: 9, height: 9)
                    }
                }

                HStack(spacing: 10) {
                    metric("Done", "\(summary.completedThisWeek)")
                    metric("Work", "\(summary.workMinutesThisWeek)m")
                    metric("Log", "\(summary.logStreak)d")
                    metric("Rate", "\(summary.completionRate)%")
                }
            }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct DashboardEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}
