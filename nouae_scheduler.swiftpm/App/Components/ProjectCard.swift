import SwiftUI

struct ProjectCard: View {
    let project: Project
    let summary: ProjectDashboardSummary
    let calendarTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.headline)
                    Label(project.category.rawValue, systemImage: project.category.symbolName)
                        .font(.caption)
                        .foregroundStyle(project.category.color)
                }
                Spacer()
                Text(calendarTitle ?? "캘린더 미연결")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                stat("오늘", summary.todayMinutes)
                stat("이번 주", summary.weekMinutes)
                VStack(alignment: .leading, spacing: 3) {
                    Text("블록")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(summary.totalBlocks)개")
                        .font(.caption.weight(.semibold))
                }
            }

            if let lastWorkedAt = summary.lastWorkedAt {
                Text("마지막 작업 \(dateText(lastWorkedAt))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(project.category.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(project.category.color.opacity(0.24), lineWidth: 1)
        )
    }

    private func stat(_ title: String, _ minutes: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(minutesText(minutes))
                .font(.caption.weight(.semibold))
        }
    }

    private func minutesText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours == 0 { return "\(remaining)분" }
        if remaining == 0 { return "\(hours)시간" }
        return "\(hours)시간 \(remaining)분"
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
