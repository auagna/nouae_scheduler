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
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                AppScreenContainer(spacing: AppUI.Spacing.section) {
                    MissionControlHeader(
                        summary: operationSummary,
                        syncText: syncSummary,
                        syncTone: syncTone
                    )

                    #if DEBUG
                    Text("MissionControlLayout ACTIVE Phase123")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red, in: Capsule())
                    #endif

                    if geometry.size.width >= 900 {
                        desktopLayout(width: geometry.size.width)
                    } else {
                        compactLayout
                    }

                    FlowMatrixPreview(relations: flowRelations)
                    sampleDataPanel
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private func desktopLayout(width: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 16) {
            SensorPanel(
                snapshot: snapshot,
                lifePulse: lifePulse,
                metrics: sensorMetrics,
                projects: activeProjects,
                showsLifePulse: true
            )
            .frame(width: max(230, width * 0.24))

            CommandCenterPanel(
                mission: currentMission,
                nextAction: nextAction,
                blocks: todayBlocks,
                projects: projects
            )
            .frame(width: max(360, width * 0.43))

            IntelligencePanel(
                insights: localInsights,
                attentionItems: attentionItems
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.section) {
            CommandCenterPanel(
                mission: currentMission,
                nextAction: nextAction,
                blocks: todayBlocks,
                projects: projects
            )
            LifePulseCard(value: lifePulse)
            SensorPanel(
                snapshot: snapshot,
                lifePulse: lifePulse,
                metrics: sensorMetrics,
                projects: activeProjects,
                showsLifePulse: false
            )
            IntelligencePanel(
                insights: localInsights,
                attentionItems: attentionItems
            )
        }
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

    private var syncTone: StatusBadge.Tone {
        projects.contains { $0.syncState == .failed } || blocks.contains { $0.syncState == .failed } ? .orange : .green
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
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        if activeProjects.contains(where: { project in !blocks.contains(where: { $0.projectId == project.id && $0.startAt > weekAgo }) }) {
            insights.append(.init(type: "Blind Spot", title: "움직이지 않는 active project", message: "active 상태지만 최근 7일간 WorkBlock이 없는 프로젝트가 있습니다."))
        }
        if blocks.filter({ $0.executionState == .delayed }).count >= 3 {
            insights.append(.init(type: "Adjustment", title: "미룸 흐름 증가", message: "미룸이 누적되고 있습니다. 긴 블록보다 짧은 실행 단위가 적합할 수 있습니다."))
        }
        if logs.filter({ Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }).isEmpty {
            insights.append(.init(type: "Pattern", title: "회고 데이터 부족", message: "이번 주 Log가 아직 적습니다. 짧은 기록 하나가 다음 조정의 재료가 됩니다."))
        }
        if insights.isEmpty {
            insights.append(.init(type: "Opportunity", title: "운영 흐름 안정", message: "현재 흐름은 큰 충돌 없이 유지되고 있습니다. 다음 행동 하나만 선명하게 잡으면 됩니다."))
        }
        return insights
    }

    private var flowRelations: [String] {
        ["Plan -> WorkBlock", "WorkBlock -> Log", "Log -> Adjustment", "Project -> Synthesis"]
    }

    private var lifePulse: Int {
        let complete = snapshot.completed * 12
        let progress = snapshot.inProgress * 8
        let delayedPenalty = snapshot.delayedToday * 8
        let logSignal = min(logs.count, 4) * 5
        return min(100, max(20, 52 + complete + progress + logSignal - delayedPenalty))
    }

    private var sensorMetrics: [DashboardMetric] {
        [
            .init(title: "Energy", value: latestFocusText),
            .init(title: "Focus", value: "\(snapshot.inProgress) active"),
            .init(title: "Mood", value: "reflection"),
            .init(title: "Weekly Momentum", value: "\(snapshot.completed) done"),
            .init(title: "Completion Rate", value: completionRateText),
            .init(title: "Inbox", value: "\(inboxCount)")
        ]
    }

    private var latestFocusText: String {
        logs.compactMap(\.focusLevel).first.map { "\($0)/5" } ?? "steady"
    }

    private var completionRateText: String {
        let total = snapshot.planned + snapshot.inProgress + snapshot.completed + snapshot.delayedToday
        guard total > 0 else { return "0%" }
        return "\(Int((Double(snapshot.completed) / Double(total)) * 100))%"
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
