import SwiftUI

struct ProjectDashboardPanel: View {
    let summary: ProjectDashboardSummary

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
            GridRow {
                metric("오늘", minutesText(summary.todayMinutes))
                metric("이번 주", minutesText(summary.weekMinutes))
            }
            GridRow {
                metric("총 작업", minutesText(summary.totalMinutes))
                metric("블록", "\(summary.totalBlocks)개")
            }
            GridRow {
                metric("마지막 작업", lastWorkedText)
                    .gridCellColumns(2)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lastWorkedText: String {
        guard let lastWorkedAt = summary.lastWorkedAt else { return "없음" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lastWorkedAt)
    }

    private func minutesText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours == 0 { return "\(remaining)분" }
        if remaining == 0 { return "\(hours)시간" }
        return "\(hours)시간 \(remaining)분"
    }
}
