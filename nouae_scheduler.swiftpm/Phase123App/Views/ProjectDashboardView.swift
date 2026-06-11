import SwiftData
import SwiftUI

struct ProjectDashboardView: View {
    let project: Project
    @EnvironmentObject private var stores: AppStores
    @Query private var blocks: [WorkBlock]
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \ProjectMemoSection.order) private var sections: [ProjectMemoSection]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]
    @State private var showingPromptExport = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ProjectCommandHeaderCard(project: project, progress: progress)

                    #if DEBUG
                    Text("ProjectMissionLayout ACTIVE Phase123")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red, in: Capsule())
                    #endif

                    if geometry.size.width >= 880 {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 14) {
                                ProjectPulsePanel(
                                    blocks: projectBlocks,
                                    logs: projectLogs,
                                    projectColor: projectColor
                                )
                                ProjectThinkingSpacePanel(sections: projectSections)
                                ProjectTrackerPanel(blocks: projectBlocks, logs: projectLogs, projectColor: projectColor)
                            }
                            .frame(width: geometry.size.width * 0.38)

                            VStack(alignment: .leading, spacing: 14) {
                                ProjectTodayWorkPanel(blocks: todayBlocks)
                                ProjectInboxPanel(tasks: projectTasks)
                                ProjectNextAdjustmentPanel(adjustments: projectAdjustments)
                            }
                            .frame(width: geometry.size.width * 0.32)

                            VStack(alignment: .leading, spacing: 14) {
                                ProjectRecentLogsPanel(logs: projectLogs)
                                ProjectIntelligencePanel(insights: projectInsights)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            ProjectPulsePanel(blocks: projectBlocks, logs: projectLogs, projectColor: projectColor)
                            ProjectTodayWorkPanel(blocks: todayBlocks)
                            ProjectInboxPanel(tasks: projectTasks)
                            ProjectNextAdjustmentPanel(adjustments: projectAdjustments)
                            ProjectThinkingSpacePanel(sections: projectSections)
                            ProjectTrackerPanel(blocks: projectBlocks, logs: projectLogs, projectColor: projectColor)
                            ProjectRecentLogsPanel(logs: projectLogs)
                            ProjectIntelligencePanel(insights: projectInsights)
                        }
                    }
                }
                .padding(18)
            }
            .background(Color(uiColor: .systemGroupedBackground))
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
                Menu(project.status.title) {
                    ForEach(ProjectStatus.allCases) { status in
                        Button(status.title) { changeStatus(status) }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPromptExport) {
            PromptExportView(initialType: .projectAnalysis, selectedProjectId: project.id)
        }
    }

    private var projectBlocks: [WorkBlock] {
        blocks.filter { $0.projectId == project.id }.sorted { $0.startAt < $1.startAt }
    }

    private var todayBlocks: [WorkBlock] {
        projectBlocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: Date()) }
    }

    private var projectTasks: [RawTask] {
        tasks.filter { $0.projectId == project.id && stores.rawTaskStore.isVisibleInInbox($0) }
    }

    private var projectSections: [ProjectMemoSection] {
        sections.filter { $0.projectId == project.id }.sorted { $0.order < $1.order }
    }

    private var projectLogs: [ProjectLog] {
        logs.filter { $0.projectId == project.id }
    }

    private var projectAdjustments: [NextAdjustment] {
        adjustments.filter { $0.projectId == project.id && $0.isActive }
    }

    private var progress: Double {
        stores.workBlockStore.calculateProjectProgress(blocks: projectBlocks)
    }

    private var projectColor: Color {
        Color(calendarHex: project.calendarColorHex)
    }

    private var projectInsights: [String] {
        var values: [String] = []
        if project.status == .active && projectBlocks.filter({ $0.startAt > Calendar.current.date(byAdding: .day, value: -7, to: Date())! }).isEmpty {
            values.append("active 상태지만 최근 7일간 WorkBlock이 없습니다.")
        }
        if projectBlocks.filter({ $0.executionState == .delayed }).count >= 2 {
            values.append("미룸이 반복됩니다. 다음 조정에서 블록 길이를 낮춰보는 것이 좋습니다.")
        }
        if projectLogs.isEmpty {
            values.append("아직 Log가 없습니다. 짧은 회고가 프로젝트의 방향성을 만듭니다.")
        }
        return values.isEmpty ? ["현재 프로젝트 흐름은 안정적입니다. 다음 실행 블록을 유지하세요."] : values
    }

    private func changeStatus(_ status: ProjectStatus) {
        try? stores.projectStore.updateProjectStatus(project: project, status: status)
    }
}

private struct ProjectCommandHeaderCard: View {
    let project: Project
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(projectColor)
                    .frame(width: 14, height: 14)
                    .padding(.top, 8)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Project Mission Control")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(project.title)
                        .font(.largeTitle.weight(.bold))
                    Text(project.goal.isEmpty ? "목표가 아직 비어 있습니다." : project.goal)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(project.type.title)
                        .font(.caption)
                    Text(project.status.title)
                        .font(.caption.weight(.semibold))
                    Text(project.syncState.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: progress)
                .tint(projectColor)
            Text("Updated \(project.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .projectCard(accent: projectColor)
    }

    private var projectColor: Color {
        Color(calendarHex: project.calendarColorHex)
    }
}

private struct ProjectPulsePanel: View {
    let blocks: [WorkBlock]
    let logs: [ProjectLog]
    let projectColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelTitle("Project Pulse", subtitle: "실행 상태")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                PulseMetric(title: "이번 주", value: "\(weekMinutes / 60)h \(weekMinutes % 60)m")
                PulseMetric(title: "완료", value: "\(blocks.filter { $0.executionState == .completed }.count)")
                PulseMetric(title: "진행", value: "\(blocks.filter { $0.executionState == .inProgress }.count)")
                PulseMetric(title: "미룸", value: "\(blocks.filter { $0.executionState == .delayed }.count)")
                PulseMetric(title: "최근 Log", value: "\(logs.prefix(7).count)")
                PulseMetric(title: "평균 집중", value: focusAverage)
            }
            ActivityDots(blocks: blocks, color: projectColor)
        }
        .projectCard()
    }

    private var weekMinutes: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return blocks
            .filter { $0.startAt >= weekAgo }
            .reduce(0) { $0 + max(0, Int($1.endAt.timeIntervalSince($1.startAt) / 60)) }
    }

    private var focusAverage: String {
        let levels = logs.compactMap(\.focusLevel)
        guard !levels.isEmpty else { return "-" }
        let average = Double(levels.reduce(0, +)) / Double(levels.count)
        return String(format: "%.1f", average)
    }
}

private struct ProjectTodayWorkPanel: View {
    let blocks: [WorkBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle("Today Work", subtitle: "오늘 움직이는 블록")
            if blocks.isEmpty {
                EmptyPanelText("오늘 배치된 WorkBlock이 없습니다.")
            }
            ForEach(blocks) { block in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(block.title)
                            .font(.subheadline.weight(.semibold))
                        Text(block.startAt.formatted(date: .omitted, time: .shortened) + " - " + block.endAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(block.executionState.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .projectCard()
    }
}

private struct ProjectInboxPanel: View {
    let tasks: [RawTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle("Project Inbox", subtitle: "아직 시간에 배치되지 않은 작업")
            if tasks.isEmpty {
                EmptyPanelText("프로젝트 Inbox가 비어 있습니다.")
            }
            ForEach(tasks.prefix(6)) { task in
                HStack {
                    Image(systemName: "tray")
                        .foregroundStyle(.secondary)
                    Text(task.title)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .projectCard()
    }
}

private struct ProjectThinkingSpacePanel: View {
    let sections: [ProjectMemoSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle("Thinking Space", subtitle: "Observation, Experiment, Insight, Synthesis")
            if sections.isEmpty {
                EmptyPanelText("아직 Thinking Section이 없습니다.")
            }
            ForEach(sections.prefix(8)) { section in
                VStack(alignment: .leading, spacing: 5) {
                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                    Text(section.content.isEmpty ? "내용 없음" : section.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .projectCard()
    }
}

private struct ProjectNextAdjustmentPanel: View {
    let adjustments: [NextAdjustment]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle("Next Adjustment", subtitle: "다음 조정")
            if adjustments.isEmpty {
                EmptyPanelText("활성 조정사항이 없습니다.")
            }
            ForEach(adjustments.prefix(4)) { item in
                Text(item.content)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .projectCard()
    }
}

private struct ProjectRecentLogsPanel: View {
    let logs: [ProjectLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle("Recent Logs", subtitle: "최근 회고")
            if logs.isEmpty {
                EmptyPanelText("최근 Log가 없습니다.")
            }
            ForEach(logs.prefix(3)) { log in
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.content.isEmpty ? "짧은 회고" : log.content)
                        .font(.subheadline)
                        .lineLimit(2)
                    Text(log.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .projectCard()
    }
}

private struct ProjectTrackerPanel: View {
    let blocks: [WorkBlock]
    let logs: [ProjectLog]
    let projectColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle("Tracker", subtitle: "행동이 쌓이는 증거")
            ActivityDots(blocks: blocks, color: projectColor)
            Text("WorkBlocks \(blocks.count) · Logs \(logs.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .projectCard()
    }
}

private struct ProjectIntelligencePanel: View {
    let insights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle("Project Intelligence", subtitle: "프로젝트 분석 노트")
            ForEach(insights, id: \.self) { insight in
                Text(insight)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .projectCard()
    }
}

private struct PanelTitle: View {
    let title: String
    let subtitle: String

    init(_ title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PulseMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ActivityDots: View {
    let blocks: [WorkBlock]
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            ForEach((0..<7), id: \.self) { offset in
                Circle()
                    .fill(hasActivity(offset: offset) ? color : Color(uiColor: .tertiarySystemFill))
                    .frame(width: 9, height: 9)
            }
        }
    }

    private func hasActivity(offset: Int) -> Bool {
        let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
        return blocks.contains { Calendar.current.isDate($0.startAt, inSameDayAs: date) }
    }
}

private struct EmptyPanelText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

private extension View {
    func projectCard(accent: Color? = nil) -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .leading) {
                if let accent {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accent)
                        .frame(width: 4)
                        .padding(.vertical, 14)
                }
            }
    }
}
