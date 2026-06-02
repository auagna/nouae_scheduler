import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]

    private var todayBlocks: [WorkBlock] { blocks.filter { Calendar.current.isDateInToday($0.startAt) } }
    private var activeProjects: [Project] { projects.filter { !$0.isArchived && $0.status != .completed } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("오늘은 \(todayBlocks.count)개의 작업 블록이 있습니다. 예정된 흐름을 확인하고, 지금 필요한 한 블록부터 시작하세요.")
                        .font(.headline)
                }
                Section("오늘 상태") {
                    HStack {
                        metric("예정", todayBlocks.filter { $0.executionState == .planned }.count)
                        metric("진행중", todayBlocks.filter { $0.executionState == .inProgress }.count)
                        metric("완료", todayBlocks.filter { $0.executionState == .completed }.count)
                    }
                }
                Section("Active Projects") {
                    ForEach(activeProjects.prefix(5)) { project in
                        NavigationLink { ProjectDashboardView(project: project) } label: { ProjectCard(project: project) }
                    }
                }
                Section("오늘 주요 WorkBlock") {
                    ForEach(todayBlocks.prefix(6)) { WorkBlockSummaryRow(block: $0) }
                }
                Section("미룸 작업") {
                    ForEach(blocks.filter { $0.executionState == .delayed }.prefix(4)) { WorkBlockSummaryRow(block: $0) }
                }
                Section("최근 다음 조정") {
                    ForEach(adjustments.filter(\.isActive).prefix(4)) { Text($0.content) }
                }
                Section("Closing Summary") {
                    Text("완료 \(todayBlocks.filter { $0.executionState == .completed }.count) · 미룸 \(todayBlocks.filter { $0.executionState == .delayed }.count) · 중단 \(todayBlocks.filter { $0.executionState == .stopped }.count)")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("nou ae")
        }
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)").font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
