import SwiftUI

enum ProjectDashboardQueueKind: String, CaseIterable, Identifiable {
    case next
    case waiting
    case review
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .next: return "Next"
        case .waiting: return "Waiting"
        case .review: return "Review"
        case .done: return "Done"
        }
    }

    var symbolName: String {
        switch self {
        case .next: return "arrow.forward.circle"
        case .waiting: return "hourglass"
        case .review: return "text.bubble"
        case .done: return "checkmark.circle"
        }
    }

    var tone: StatusBadge.Tone {
        switch self {
        case .next: return .blue
        case .waiting: return .orange
        case .review: return .purple
        case .done: return .green
        }
    }
}

enum ProjectDashboardQueueSource {
    case rawTask
    case workBlock
}

struct ProjectDashboardQueueItem: Identifiable {
    let kind: ProjectDashboardQueueKind
    let source: ProjectDashboardQueueSource
    let sourceId: UUID
    let rawTaskId: UUID?
    let blockId: UUID?
    let title: String
    let subtitle: String
    let detail: String
    let syncText: String
    let date: Date

    var id: String {
        "\(kind.rawValue)-\(sourceId.uuidString)"
    }
}

struct ProjectDashboardFocusSnapshot: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let areaText: String
    let memo: String
    let stateText: String
    let syncText: String
    let remainingText: String?
    let blockId: UUID?
}

struct ProjectDashboardTrackerSummary {
    let activity: [Bool]
    let weeklyMinutes: Int
    let completedBlocks: Int
    let planDoneRatio: Double
    let logCount: Int
    let recentActivity: String
    let topMood: String?
    let topBlocker: String?
}

struct ProjectDashboardAttentionItem: Identifiable {
    enum Priority {
        case high
        case medium
        case low

        var tone: StatusBadge.Tone {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .neutral
            }
        }

        var title: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }
    }

    let id = UUID()
    let title: String
    let detail: String
    let priority: Priority
    let symbolName: String
}

struct ProjectMVPHeader: View {
    let projectTitle: String
    let areaName: String
    let projectType: String
    let lifecycleTitle: String
    let areaColor: Color
    let calendarState: String
    let reminderState: String
    let lastActivityText: String
    let isArchived: Bool

    var body: some View {
        AppPanel(title: "Project Mission Control", subtitle: "선택한 프로젝트의 현재 운영 흐름입니다.") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(areaColor)
                        .frame(width: 13, height: 13)
                        .padding(.top, 9)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(projectTitle)
                            .font(.largeTitle.bold())
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            StatusBadge(lifecycleTitle, tone: lifecycleTone, symbolName: lifecycleSymbol)
                            StatusBadge(projectType, tone: .neutral, symbolName: "folder")
                            if isArchived {
                                StatusBadge("Archived", tone: .orange, symbolName: "archivebox")
                            }
                        }
                    }

                    Spacer(minLength: 8)
                }

                AppDivider()

                HStack(alignment: .top, spacing: 10) {
                    ProjectHeaderMeta(title: "Area", value: areaName)
                    ProjectHeaderMeta(title: "Calendar", value: calendarState)
                    ProjectHeaderMeta(title: "Reminders", value: reminderState)
                    ProjectHeaderMeta(title: "Last Activity", value: lastActivityText)
                }
            }
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(areaColor)
                .frame(width: 4)
                .padding(.vertical, 18)
        }
    }

    private var lifecycleTone: StatusBadge.Tone {
        switch lifecycleTitle {
        case "Active": return .green
        case "Completed": return .blue
        default: return .neutral
        }
    }

    private var lifecycleSymbol: String {
        switch lifecycleTitle {
        case "Active": return "play.circle"
        case "Completed": return "checkmark.circle"
        default: return "circle"
        }
    }
}

private struct ProjectHeaderMeta: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProjectMVPCurrentFocusPanel: View {
    let focus: ProjectDashboardFocusSnapshot?
    let suggestedNext: ProjectDashboardQueueItem?
    let accentColor: Color
    let onStart: () -> Void
    let onComplete: () -> Void
    let onDelay: () -> Void
    let onStop: () -> Void
    let onOpenPlan: () -> Void

    var body: some View {
        AppPanel(title: "Current Project Focus", subtitle: "지금 이 프로젝트에서 움직여야 할 항목입니다.") {
            VStack(alignment: .leading, spacing: 14) {
                if let focus {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(focus.title)
                                    .font(.title3.weight(.semibold))
                                    .lineLimit(2)
                                Text(focus.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                StatusBadge(focus.stateText, tone: .blue)
                                StatusBadge(focus.syncText, tone: .neutral)
                            }
                        }

                        HStack(spacing: 8) {
                            Label(focus.areaText, systemImage: "folder")
                            if let remainingText = focus.remainingText {
                                Label(remainingText, systemImage: "timer")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if !focus.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(focus.memo)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }

                    AppDivider()

                    HStack(spacing: 8) {
                        Button("Start", action: onStart)
                            .buttonStyle(.borderedProminent)
                            .disabled(focus.blockId == nil)
                        Button("Complete", action: onComplete)
                            .buttonStyle(.bordered)
                            .disabled(focus.blockId == nil)
                        Button("Delay", action: onDelay)
                            .buttonStyle(.bordered)
                            .disabled(focus.blockId == nil)
                        Button("Stop", role: .destructive, action: onStop)
                            .buttonStyle(.bordered)
                            .disabled(focus.blockId == nil)
                        Spacer()
                        Button {
                            onOpenPlan()
                        } label: {
                            Label("Open in Plan", systemImage: "calendar.badge.clock")
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.caption.weight(.semibold))
                } else {
                    Text("현재 이 프로젝트에서 실행 중인 작업이 없습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let suggestedNext {
                        AppDivider()
                        ProjectMVPQueueRow(item: suggestedNext, onOpenPlan: onOpenPlan, onWriteLog: {})
                    }
                }
            }
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 4)
                .padding(.vertical, 18)
        }
    }
}

struct ProjectMVPOperationalQueuePanel: View {
    @Binding var selectedKind: ProjectDashboardQueueKind
    let counts: [ProjectDashboardQueueKind: Int]
    let items: [ProjectDashboardQueueItem]
    let onOpenPlan: (ProjectDashboardQueueItem) -> Void
    let onWriteLog: (ProjectDashboardQueueItem) -> Void

    var body: some View {
        AppPanel(title: "Project Operational Queue", subtitle: "저장된 상태가 아니라 현재 프로젝트 데이터에서 계산한 운영 큐입니다.") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Queue", selection: $selectedKind) {
                    ForEach(ProjectDashboardQueueKind.allCases) { kind in
                        Text("\(kind.title) \(counts[kind, default: 0])").tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                ProjectMVPQueueCountStrip(counts: counts)

                if items.isEmpty {
                    ProjectDashboardEmptyState(
                        symbolName: selectedKind.symbolName,
                        title: "\(selectedKind.title) 비어 있음",
                        message: emptyMessage
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(items.prefix(8)) { item in
                            ProjectMVPQueueRow(
                                item: item,
                                onOpenPlan: { onOpenPlan(item) },
                                onWriteLog: { onWriteLog(item) }
                            )
                        }
                    }
                }
            }
        }
    }

    private var emptyMessage: String {
        switch selectedKind {
        case .next: return "지금 바로 움직일 항목이 없습니다."
        case .waiting: return "기다리는 항목이 없습니다."
        case .review: return "회고가 필요한 완료 항목이 없습니다."
        case .done: return "회고까지 닫힌 완료 항목이 없습니다."
        }
    }
}

private struct ProjectMVPQueueCountStrip: View {
    let counts: [ProjectDashboardQueueKind: Int]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ProjectDashboardQueueKind.allCases) { kind in
                HStack(spacing: 5) {
                    Image(systemName: kind.symbolName)
                    Text(kind.title)
                    Text("\(counts[kind, default: 0])")
                        .fontWeight(.semibold)
                }
                .font(.caption2)
                .foregroundStyle(kind.tone.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(kind.tone.color.opacity(0.1), in: Capsule())
            }
        }
    }
}

private struct ProjectMVPQueueRow: View {
    let item: ProjectDashboardQueueItem
    let onOpenPlan: () -> Void
    let onWriteLog: () -> Void

    var body: some View {
        AppListRow(
            title: item.title,
            subtitle: "\(item.subtitle) · \(item.detail)",
            leading: {
                Image(systemName: item.kind.symbolName)
                    .foregroundStyle(item.kind.tone.color)
            },
            trailing: {
                HStack(spacing: 6) {
                    StatusBadge(item.syncText, tone: .neutral)
                    Button(actionTitle, action: primaryAction)
                        .buttonStyle(.bordered)
                }
            }
        )
    }

    private var actionTitle: String {
        switch item.kind {
        case .next, .waiting: return "Plan"
        case .review: return "Log"
        case .done: return "View"
        }
    }

    private func primaryAction() {
        switch item.kind {
        case .next, .waiting, .done:
            onOpenPlan()
        case .review:
            onWriteLog()
        }
    }
}

struct ProjectMVPTodayTimelinePanel: View {
    let blocks: [WorkBlock]
    let focusBlockId: UUID?
    let accentColor: Color
    let onOpenPlan: () -> Void

    var body: some View {
        AppPanel(title: "Today Timeline", subtitle: "현재 프로젝트의 오늘 WorkBlock만 compact하게 봅니다.") {
            if blocks.isEmpty {
                ProjectDashboardEmptyState(
                    symbolName: "calendar",
                    title: "오늘 배치된 블록 없음",
                    message: "Plan에서 RawTask를 시간 위에 배치하면 여기에 나타납니다."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(blocks) { block in
                        AppListRow(
                            title: block.title,
                            subtitle: "\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))",
                            leading: {
                                Circle()
                                    .fill(block.id == focusBlockId ? accentColor : accentColor.opacity(0.35))
                                    .frame(width: 10, height: 10)
                            },
                            trailing: {
                                StatusBadge(block.executionState.title, tone: block.executionState == .completed ? .green : .neutral)
                            }
                        )
                    }
                }
            }

            Button {
                onOpenPlan()
            } label: {
                Label("Open Today in Plan", systemImage: "calendar.badge.clock")
            }
            .buttonStyle(.bordered)
            .font(.caption.weight(.semibold))
        }
    }
}

struct ProjectMVPBriefPanel: View {
    let goal: String
    let sections: [ProjectMemoSection]
    let onAddMissingSections: () -> Void

    var body: some View {
        AppPanel(title: "Project Brief", subtitle: "목적과 현재 방향만 짧게 유지합니다.") {
            VStack(alignment: .leading, spacing: 12) {
                ProjectBriefLine(title: "Goal", content: goal.isEmpty ? "목표가 아직 비어 있습니다." : goal)

                ForEach(sections.prefix(4)) { section in
                    ProjectBriefLine(title: section.title, content: section.content.isEmpty ? "내용 없음" : section.content)
                }

                Button {
                    onAddMissingSections()
                } label: {
                    Label("Add Missing Template Sections", systemImage: "plus.rectangle.on.folder")
                }
                .buttonStyle(.bordered)
                .font(.caption.weight(.semibold))
            }
        }
    }
}

private struct ProjectBriefLine: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(content)
                .font(.subheadline)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProjectMVPNextAdjustmentPanel: View {
    let active: [NextAdjustment]
    let recent: [NextAdjustment]

    var body: some View {
        AppPanel(title: "Next Adjustment", subtitle: "다음 실행에서 바꿀 한 가지입니다.") {
            if active.isEmpty {
                ProjectDashboardEmptyState(
                    symbolName: "slider.horizontal.3",
                    title: "아직 다음 조정이 없습니다.",
                    message: "최근 완료 작업을 회고해 다음 조정을 남겨보세요."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(active.prefix(2)) { adjustment in
                        AppListRow(
                            title: adjustment.content,
                            subtitle: adjustment.createdAt.formatted(date: .abbreviated, time: .shortened),
                            leading: {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundStyle(.blue)
                            },
                            trailing: {
                                StatusBadge("Active", tone: .blue)
                            }
                        )
                    }
                }
            }

            if !recent.isEmpty {
                AppDivider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(recent.prefix(2)) { adjustment in
                        Text(adjustment.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }
}

struct ProjectMVPSpacePreviewPanel: View {
    let project: Project
    let areas: [ProjectArea]
    let projects: [Project]
    let notes: [ProjectNote]
    let boardItems: [ProjectBoardItem]

    var body: some View {
        AppPanel(title: "Project Space", subtitle: "Project Page와 Notes는 요약과 진입점만 제공합니다.") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ProjectSpaceMetric(title: "References", value: "\(referenceCount)", symbolName: "bookmark")
                    ProjectSpaceMetric(title: "Sketches", value: "\(sketchCount)", symbolName: "pencil.and.scribble")
                    ProjectSpaceMetric(title: "Notes", value: "\(notes.count)", symbolName: "book.closed")
                }

                if let firstItem = boardItems.first {
                    AppListRow(
                        title: firstItem.title,
                        subtitle: "Project Page · \(firstItem.itemType.title)",
                        leading: {
                            Image(systemName: firstItem.itemType.symbolName)
                                .foregroundStyle(Color(calendarHex: firstItem.colorHex))
                        },
                        trailing: {
                            StatusBadge("Page", tone: .neutral)
                        }
                    )
                }

                if notes.isEmpty {
                    Text("아직 Project Note가 없습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(notes.prefix(3)) { note in
                        AppListRow(
                            title: note.title,
                            subtitle: "\(note.noteType.title) · \(note.updatedAt.formatted(date: .abbreviated, time: .omitted))",
                            leading: {
                                Image(systemName: note.noteType.symbolName)
                                    .foregroundStyle(.secondary)
                            },
                            trailing: {
                                EmptyView()
                            }
                        )
                    }
                }

                HStack {
                    NavigationLink {
                        ProjectPageView(project: project)
                    } label: {
                        Label("Open Project Page", systemImage: "square.grid.2x2")
                    }
                    .buttonStyle(.bordered)

                    NavigationLink {
                        ProjectsNotesView(areas: areas, projects: projects)
                    } label: {
                        Label("Open Notes", systemImage: "book.closed")
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption.weight(.semibold))
            }
        }
    }

    private var referenceCount: Int {
        boardItems.filter { $0.itemType == .reference || $0.itemType == .link || $0.itemType == .image }.count
    }

    private var sketchCount: Int {
        boardItems.filter { $0.itemType == .sketch }.count
    }
}

private struct ProjectSpaceMetric: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbolName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ProjectMVPRecentReflectionPanel: View {
    let logs: [ProjectLog]
    let onWriteLog: () -> Void

    var body: some View {
        AppPanel(title: "Recent Reflection", subtitle: "Log는 요약만 보여주고 작성은 sheet로 엽니다.") {
            if logs.isEmpty {
                ProjectDashboardEmptyState(
                    symbolName: "text.bubble",
                    title: "최근 회고 없음",
                    message: "1분짜리 Log가 프로젝트 흐름을 닫아줍니다."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(logs.prefix(3)) { log in
                        AppListRow(
                            title: log.title.isEmpty ? log.logType.title : log.title,
                            subtitle: reflectionSubtitle(for: log),
                            leading: {
                                Image(systemName: "text.bubble")
                                    .foregroundStyle(.secondary)
                            },
                            trailing: {
                                if let focus = log.focusLevel {
                                    StatusBadge("Focus \(focus)", tone: .neutral)
                                }
                            }
                        )
                    }
                }
            }

            Button {
                onWriteLog()
            } label: {
                Label("Write Project Log", systemImage: "square.and.pencil")
            }
            .buttonStyle(.bordered)
            .font(.caption.weight(.semibold))
        }
    }

    private func reflectionSubtitle(for log: ProjectLog) -> String {
        let tags = (log.moodTags + log.blockerTags).prefix(3).joined(separator: ", ")
        let content = log.content.isEmpty ? log.nextAdjustment : log.content
        return [log.createdAt.formatted(date: .abbreviated, time: .omitted), tags, content]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

struct ProjectMVPCompactTrackerPanel: View {
    let summary: ProjectDashboardTrackerSummary
    let accentColor: Color

    var body: some View {
        AppPanel(title: "Compact Tracker", subtitle: "행동이 쌓이는 최소 증거만 표시합니다.") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(Array(summary.activity.enumerated()), id: \.offset) { _, active in
                        Circle()
                            .fill(active ? accentColor : Color(uiColor: .tertiarySystemFill))
                            .frame(width: 9, height: 9)
                    }
                }

                HStack(spacing: 8) {
                    ProjectTrackerMetric(title: "Week Work", value: minutesText(summary.weeklyMinutes))
                    ProjectTrackerMetric(title: "Done", value: "\(summary.completedBlocks)")
                    ProjectTrackerMetric(title: "Plan/Done", value: "\(Int(summary.planDoneRatio * 100))%")
                }

                Text("Logs \(summary.logCount) · Last \(summary.recentActivity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    if let mood = summary.topMood {
                        StatusBadge(mood, tone: .purple)
                    }
                    if let blocker = summary.topBlocker {
                        StatusBadge(blocker, tone: .orange)
                    }
                }
            }
        }
    }

    private func minutesText(_ minutes: Int) -> String {
        "\(minutes / 60)h \(minutes % 60)m"
    }
}

private struct ProjectTrackerMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ProjectMVPAttentionPanel: View {
    let items: [ProjectDashboardAttentionItem]
    let compactInsight: String

    var body: some View {
        AppPanel(title: "Project Attention", subtitle: "해결이 필요한 항목만 조용히 표시합니다.") {
            if items.isEmpty {
                ProjectDashboardEmptyState(
                    symbolName: "checkmark.seal",
                    title: "주의 항목 없음",
                    message: "현재 프로젝트 운영 흐름에 큰 막힘은 보이지 않습니다."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(items.prefix(5)) { item in
                        AppListRow(
                            title: item.title,
                            subtitle: item.detail,
                            leading: {
                                Image(systemName: item.symbolName)
                                    .foregroundStyle(item.priority.tone.color)
                            },
                            trailing: {
                                StatusBadge(item.priority.title, tone: item.priority.tone)
                            }
                        )
                    }
                }
            }

            AppDivider()
            VStack(alignment: .leading, spacing: 5) {
                Text("Insight")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(compactInsight)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ProjectDashboardEmptyState: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
