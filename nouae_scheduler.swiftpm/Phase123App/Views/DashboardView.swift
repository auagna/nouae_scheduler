import Foundation
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var stores: AppStores
    @Query private var projects: [Project]
    @Query private var tasks: [RawTask]
    @Query private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]
    @State private var message: String?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        MissionControlHeader(
                            summary: operationSummary,
                            lastSyncText: syncSummary
                        )

                        Text("MissionControlLayout ACTIVE Phase123")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red, in: Capsule())

                        if geometry.size.width >= 900 {
                            HStack(alignment: .top, spacing: 14) {
                                SensorColumn(
                                    snapshot: snapshot,
                                    projects: activeProjects,
                                    logs: logs
                                )
                                .frame(width: geometry.size.width * 0.25)

                                CommandCenterColumn(
                                    mission: currentMission,
                                    nextAction: nextAction,
                                    blocks: todayBlocks,
                                    projects: projects
                                )
                                .frame(width: geometry.size.width * 0.42)

                                IntelligenceColumn(
                                    insights: localInsights,
                                    attentionItems: attentionItems
                                )
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 14) {
                                CommandCenterColumn(
                                    mission: currentMission,
                                    nextAction: nextAction,
                                    blocks: todayBlocks,
                                    projects: projects
                                )
                                SensorColumn(snapshot: snapshot, projects: activeProjects, logs: logs)
                                IntelligenceColumn(insights: localInsights, attentionItems: attentionItems)
                            }
                        }

                        FlowMatrixPreviewCard(relations: flowRelations)

                        SampleDataControls(message: message, seed: seed, remove: removeSampleData)
                    }
                    .padding(18)
                }
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .navigationTitle("Mission Control")
        }
    }

    private var snapshot: DashboardSnapshot {
        stores.dashboardStore.snapshot(projects: projects, blocks: blocks, logs: logs, adjustments: adjustments)
    }

    private var todayBlocks: [WorkBlock] {
        blocks
            .filter { Calendar.current.isDate($0.startAt, inSameDayAs: Date()) }
            .sorted { $0.startAt < $1.startAt }
    }

    private var activeProjects: [Project] {
        projects
            .filter { $0.status == .active || $0.status == .scheduled }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var inboxCount: Int {
        tasks.filter { stores.rawTaskStore.isVisibleInInbox($0) }.count
    }

    private var currentMission: String {
        let moving = activeProjects.prefix(2).map(\.title).joined(separator: "와 ")
        if !moving.isEmpty {
            return "오늘은 \(moving)이 핵심 흐름입니다."
        }
        if inboxCount > 0 {
            return "Inbox \(inboxCount)개를 시간 위에 배치하는 것이 오늘의 첫 흐름입니다."
        }
        return "오늘의 운영 흐름을 가볍게 정리할 준비가 되어 있습니다."
    }

    private var operationSummary: String {
        "오늘은 \(todayBlocks.count)개의 WorkBlock과 \(activeProjects.count)개의 active project가 움직이고 있습니다."
    }

    private var syncSummary: String {
        let failedProjects = projects.filter { $0.syncState == .failed }.count
        let failedBlocks = blocks.filter { $0.syncState == .failed }.count
        return failedProjects + failedBlocks == 0 ? "Sync stable" : "Sync attention \(failedProjects + failedBlocks)"
    }

    private var nextAction: WorkBlock? {
        let now = Date()
        return todayBlocks
            .filter { $0.executionState == .planned || $0.executionState == .inProgress }
            .sorted { abs($0.startAt.timeIntervalSince(now)) < abs($1.startAt.timeIntervalSince(now)) }
            .first
    }

    private var attentionItems: [String] {
        var items: [String] = []
        let delayed = blocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: Date()) && $0.executionState == .delayed }.count
        let stopped = blocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: Date()) && $0.executionState == .stopped }.count
        let failed = blocks.filter { $0.syncState == .failed }.count + projects.filter { $0.syncState == .failed }.count
        if delayed > 0 { items.append("미룸 WorkBlock \(delayed)개가 오늘 흐름에서 빠졌습니다.") }
        if stopped > 0 { items.append("중단된 WorkBlock \(stopped)개가 있습니다.") }
        if failed > 0 { items.append("동기화 실패 항목 \(failed)개를 확인해야 합니다.") }
        if logs.isEmpty { items.append("최근 회고 Log가 없습니다.") }
        return items.isEmpty ? ["주의가 필요한 항목은 없습니다."] : items
    }

    private var localInsights: [DashboardInsight] {
        var insights: [DashboardInsight] = []
        if activeProjects.contains(where: { project in !blocks.contains(where: { $0.projectId == project.id && $0.startAt > Calendar.current.date(byAdding: .day, value: -7, to: Date())! }) }) {
            insights.append(.init(type: "Blind Spot", title: "움직이지 않는 active project", message: "active 상태지만 최근 7일간 WorkBlock이 없는 프로젝트가 있습니다."))
        }
        if blocks.filter({ $0.executionState == .delayed }).count >= 3 {
            insights.append(.init(type: "Adjustment", title: "미룸 흐름 증가", message: "미룸이 누적되고 있습니다. 긴 블록보다 짧은 실행 단위가 적합할 수 있습니다."))
        }
        if logs.filter({ Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }).count == 0 {
            insights.append(.init(type: "Pattern", title: "회고 데이터 부족", message: "이번 주 Log가 아직 적습니다. 짧은 기록 하나가 다음 조정의 재료가 됩니다."))
        }
        if insights.isEmpty {
            insights.append(.init(type: "Opportunity", title: "운영 흐름 안정", message: "현재 흐름은 큰 충돌 없이 유지되고 있습니다. 다음 행동 하나만 선명하게 잡으면 됩니다."))
        }
        return insights
    }

    private var flowRelations: [String] {
        ["Plan → WorkBlock", "WorkBlock → Log", "Log → Adjustment", "Project → Synthesis"]
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

private struct DashboardInsight: Identifiable {
    let id = UUID()
    let type: String
    let title: String
    let message: String
}

private struct MissionControlHeader: View {
    let summary: String
    let lastSyncText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mission Control")
                        .font(.largeTitle.weight(.bold))
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Date(), style: .date)
                        .font(.subheadline.weight(.semibold))
                    Text(lastSyncText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SensorColumn: View {
    let snapshot: DashboardSnapshot
    let projects: [Project]
    let logs: [ProjectLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardPanelTitle("Sensor", subtitle: "현재 상태 감지")
            LifePulseCard(value: lifePulse)
            CompactStatusStrip(snapshot: snapshot)
            SensorMetricGrid(metrics: metrics)
            ActiveProjectCompactList(projects: projects)
        }
    }

    private var lifePulse: Int {
        let complete = (Int(snapshot.completed) ?? 0) * 12
        let progress = (Int(snapshot.inProgress) ?? 0) * 8
        let delayedPenalty = (Int(snapshot.delayedToday) ?? 0) * 8
        let logSignal = min(logs.count, 4) * 5
        return min(100, max(20, 52 + complete + progress + logSignal - delayedPenalty))
    }

    private var metrics: [(String, String)] {
        [
            ("Energy", logs.first?.focusLevel.map { "\($0)/5" } ?? "steady"),
            ("Mood", "reflection"),
            ("Focus", "\(snapshot.inProgress) active"),
            ("Stress", snapshot.delayedToday == "0" ? "low" : "watch"),
            ("Sleep", "not logged"),
            ("Recovery", "neutral")
        ]
    }
}

private struct CommandCenterColumn: View {
    let mission: String
    let nextAction: WorkBlock?
    let blocks: [WorkBlock]
    let projects: [Project]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardPanelTitle("Command Center", subtitle: "지금 움직일 흐름")
            CurrentMissionCard(text: mission)
            if let nextAction {
                NextActionCard(block: nextAction, projectTitle: projectTitle(for: nextAction))
            }
            TodayBlocksCompactList(blocks: blocks, projects: projects)
            DeepWorkPlaceholder()
        }
    }

    private func projectTitle(for block: WorkBlock) -> String? {
        projects.first { $0.id == block.projectId }?.title
    }
}

private struct IntelligenceColumn: View {
    let insights: [DashboardInsight]
    let attentionItems: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardPanelTitle("Intelligence", subtitle: "패턴과 조정")
            ForEach(insights) { insight in
                InsightPreviewCard(insight: insight)
            }
            AttentionCard(items: attentionItems)
        }
    }
}

private struct DashboardPanelTitle: View {
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

private struct LifePulseCard: View {
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Life Pulse")
                    .font(.headline)
                Spacer()
                Text("\(value)")
                    .font(.title.weight(.bold))
            }
            ProgressView(value: Double(value), total: 100)
                .tint(.blue)
            HStack {
                Label("Energy", systemImage: "bolt.fill")
                Spacer()
                Label("Focus", systemImage: "scope")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .dashboardCard()
    }
}

private struct CompactStatusStrip: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        HStack(spacing: 8) {
            StatusPill(title: "예정", value: snapshot.planned, tint: .blue)
            StatusPill(title: "진행", value: snapshot.inProgress, tint: .orange)
            StatusPill(title: "완료", value: snapshot.completed, tint: .green)
            StatusPill(title: "미룸", value: snapshot.delayedToday, tint: .secondary)
        }
    }
}

private struct StatusPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SensorMetricGrid: View {
    let metrics: [(String, String)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(metrics, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.1)
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .dashboardCard()
    }
}

private struct ActiveProjectCompactList: View {
    let projects: [Project]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Projects")
                .font(.subheadline.weight(.semibold))
            if projects.isEmpty {
                Text("active project가 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(projects.prefix(5)) { project in
                HStack(spacing: 8) {
                    Circle()
                        .fill(project.calendarColor)
                        .frame(width: 8, height: 8)
                    Text(project.title)
                        .font(.caption)
                    Spacer()
                    Text(project.status.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .dashboardCard()
    }
}

private struct CurrentMissionCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Mission")
                .font(.headline)
            Text(text)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .dashboardCard(accent: .blue)
    }
}

private struct NextActionCard: View {
    let block: WorkBlock
    let projectTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Action")
                .font(.headline)
            Text(block.title)
                .font(.title3.weight(.semibold))
            Text(timeText)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let projectTitle {
                Text(projectTitle)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }
        }
        .dashboardCard(accent: .orange)
    }

    private var timeText: String {
        block.startAt.formatted(date: .omitted, time: .shortened) + " - " + block.endAt.formatted(date: .omitted, time: .shortened)
    }
}

private struct TodayBlocksCompactList: View {
    let blocks: [WorkBlock]
    let projects: [Project]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today’s Time Blocks")
                .font(.headline)
            if blocks.isEmpty {
                Text("오늘 배치된 WorkBlock이 없습니다.")
                    .foregroundStyle(.secondary)
            }
            ForEach(blocks.prefix(8)) { block in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(project(for: block)?.calendarColor ?? Color.blue)
                        .frame(width: 4)
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
        .dashboardCard()
    }

    private func project(for block: WorkBlock) -> Project? {
        projects.first { $0.id == block.projectId }
    }
}

private struct DeepWorkPlaceholder: View {
    var body: some View {
        HStack {
            Label("Deep Work Timer", systemImage: "timer")
            Spacer()
            Text("ready later")
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .dashboardCard()
    }
}

private struct InsightPreviewCard: View {
    let insight: DashboardInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(insight.type)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(insight.title)
                .font(.subheadline.weight(.semibold))
            Text(insight.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dashboardCard()
    }
}

private struct AttentionCard: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attention")
                .font(.headline)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "smallcircle.filled.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .dashboardCard()
    }
}

private struct FlowMatrixPreviewCard: View {
    let relations: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardPanelTitle("Flow Matrix", subtitle: "행동과 결과의 관계")
            HStack(spacing: 10) {
                ForEach(relations, id: \.self) { relation in
                    Text(relation)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .dashboardCard()
    }
}

private struct SampleDataControls: View {
    let message: String?
    let seed: () -> Void
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("샘플 데이터 생성", action: seed)
                Button("샘플 데이터 제거", role: .destructive, action: remove)
            }
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .dashboardCard()
    }
}

private extension View {
    func dashboardCard(accent: Color? = nil) -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
            }
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

private extension Project {
    var calendarColor: Color {
        Color(calendarHex: calendarColorHex)
    }
}
