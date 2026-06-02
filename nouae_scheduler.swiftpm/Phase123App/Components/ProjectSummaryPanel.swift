import SwiftUI

struct ProjectSummaryPanel: View {
    let project: Project
    let blocks: [WorkBlock]
    let recentLog: ProjectLog?

    private var progress: Double { blocks.isEmpty ? 0 : Double(blocks.filter { $0.executionState == .completed }.count) / Double(blocks.count) }
    private var todayCount: Int { blocks.filter { Calendar.current.isDateInToday($0.startAt) }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(project.goal.isEmpty ? "목표를 입력하세요." : project.goal)
            ProgressView(value: progress) { Text("진행률 \(Int(progress * 100))%") }
            HStack { Label("오늘 \(todayCount)개", systemImage: "clock"); Spacer(); Label("남은 시간 추후 연결", systemImage: "hourglass") }
                .font(.caption).foregroundStyle(.secondary)
            Text(recentLog?.content ?? "최근 로그 없음").font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
    }
}
