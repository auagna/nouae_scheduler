import SwiftUI

struct ProjectCard: View {
    let project: Project
    let blocks: [WorkBlock]
    let logs: [ProjectLog]

    private var todayCount: Int { blocks.filter { Calendar.current.isDateInToday($0.startAt) }.count }
    private var progress: Double { blocks.isEmpty ? 0 : Double(blocks.filter { $0.executionState == .completed }.count) / Double(blocks.count) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(Color(calendarHex: project.calendarColorHex)).frame(width: 12, height: 12).padding(.top, 5)
            VStack(alignment: .leading, spacing: 5) {
                Text(project.title).font(.headline)
                Text(project.status.title + " · 오늘 작업 \(todayCount)개").font(.caption).foregroundStyle(.secondary)
                ProgressView(value: progress)
                Text(logs.first?.content ?? "최근 로그 없음").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                SyncStatusBadge(state: project.syncState)
            }
        }
        .padding(.vertical, 5)
        .opacity(project.status == .archived ? 0.55 : 1)
    }
}
