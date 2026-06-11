import SwiftUI

struct BlockSyncStatusCard: View {
    let calendarIdentifier: String?
    let reminderListIdentifier: String?
    let isWorking: Bool
    let onEnsure: () -> Void

    var body: some View {
        AppPanel(title: "BLOCK Status", subtitle: "Project가 정해지지 않은 항목의 임시 Calendar / Reminder List입니다.") {
            StatusLine(title: "BLOCK Calendar", identifier: calendarIdentifier)
            StatusLine(title: "BLOCK Reminder List", identifier: reminderListIdentifier)
            Button(action: onEnsure) {
                if isWorking { ProgressView() }
                else { Label("BLOCK 재생성 / 확인", systemImage: "arrow.triangle.2.circlepath") }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct StatusLine: View {
    let title: String
    let identifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                StatusBadge(identifier == nil ? "Missing" : "Ready", tone: identifier == nil ? .orange : .green)
            }
            if let identifier {
                Text(identifier)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
