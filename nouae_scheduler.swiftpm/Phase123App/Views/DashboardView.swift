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
            List {
                Section {
                    Text(briefing)
                        .font(.headline)
                    Text("오늘의 흐름을 확인하고 필요한 조정만 남겨 보세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("오늘 상태") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            StatCard(title: "예정", value: snapshot.planned, systemImage: "calendar", tint: .blue)
                            StatCard(title: "진행 중", value: snapshot.inProgress, systemImage: "timer", tint: .orange)
                            StatCard(title: "완료", value: snapshot.completed, systemImage: "checkmark.circle", tint: .green)
                            StatCard(title: "미룸", value: snapshot.delayedBlocks.count, systemImage: "arrowshape.turn.up.right", tint: .secondary)
                        }
                    }
                }
                Section("Active Projects") {
                    if snapshot.activeProjects.isEmpty { empty("진행 중인 프로젝트가 없습니다.") }
                    ForEach(snapshot.activeProjects) { project in
                        ProjectCard(
                            project: project,
                            blocks: blocks.filter { $0.projectId == project.id },
                            logs: logs.filter { $0.projectId == project.id }
                        )
                    }
                }
                Section("오늘 WorkBlock") {
                    if snapshot.todayBlocks.isEmpty { empty("오늘 배치된 WorkBlock이 없습니다.") }
                    ForEach(snapshot.todayBlocks) { block in
                        DashboardWorkBlockRow(block: block, projectTitle: projects.first { $0.id == block.projectId }?.title)
                    }
                }
                Section("미룸 작업") {
                    if snapshot.delayedBlocks.isEmpty { empty("미룬 작업이 없습니다.") }
                    ForEach(snapshot.delayedBlocks.prefix(4)) { block in
                        DashboardWorkBlockRow(block: block, projectTitle: projects.first { $0.id == block.projectId }?.title)
                    }
                }
                Section("최근 Next Adjustment") {
                    if snapshot.recentAdjustments.isEmpty { empty("최근 조정사항이 없습니다.") }
                    ForEach(snapshot.recentAdjustments) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.content)
                            Text(projects.first { $0.id == item.projectId }?.title ?? "프로젝트 없음")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("최근 Log") {
                    if snapshot.recentLogs.isEmpty { empty("최근 Log가 없습니다.") }
                    ForEach(snapshot.recentLogs) { log in
                        LogEntryCard(
                            log: log,
                            projectTitle: projects.first { $0.id == log.projectId }?.title,
                            workBlockTitle: blocks.first { $0.id == log.workBlockId }?.title
                        )
                    }
                }
                Section("Closing Summary") {
                    Text(snapshot.closingSummary)
                }
                Section {
                    Button("샘플 데이터 생성") { seed() }
                }
                if let message {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Dashboard")
        }
    }

    private var snapshot: DashboardSnapshot {
        stores.dashboardStore.snapshot(projects: projects, blocks: blocks, logs: logs, adjustments: adjustments)
    }

    private var briefing: String {
        let visibleInboxCount = tasks.filter { stores.rawTaskStore.isVisibleInInbox($0) }.count
        return visibleInboxCount == 0 ? "Inbox가 비어 있습니다." : "오늘 확인할 Inbox가 \(visibleInboxCount)개 있습니다."
    }

    private func empty(_ text: String) -> some View {
        Text(text).foregroundStyle(.secondary)
    }

    private func seed() {
        do {
            try SampleDataSeeder.seed(context: context, stores: stores)
            message = "샘플 데이터를 확인했습니다."
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct DashboardWorkBlockRow: View {
    let block: WorkBlock
    let projectTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(block.title)
                Spacer()
                Text(block.executionState.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(block.startAt.formatted(date: .omitted, time: .shortened) + " - " + block.endAt.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
            if let projectTitle {
                Text(projectTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
