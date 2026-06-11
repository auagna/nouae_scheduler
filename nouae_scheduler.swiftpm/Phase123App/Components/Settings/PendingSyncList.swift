import SwiftUI

struct PendingSyncList: View {
    let blocks: [WorkBlock]
    let tasks: [RawTask]
    let onRetryAll: () -> Void

    var body: some View {
        AppPanel(title: "Pending Sync", subtitle: "아직 Apple Calendar / Reminders로 보내지지 않은 항목입니다.") {
            syncSummary
            Button("Retry All", action: onRetryAll)
                .buttonStyle(.borderedProminent)
                .disabled(blocks.isEmpty && tasks.isEmpty)
        }
    }

    private var syncSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppListRow(title: "Calendar Events", subtitle: "\(blocks.count) pending WorkBlocks") {
                Image(systemName: "calendar")
            } trailing: {
                StatusBadge("\(blocks.count)", tone: blocks.isEmpty ? .neutral : .orange)
            }
            AppListRow(title: "Reminders", subtitle: "\(tasks.count) pending RawTasks") {
                Image(systemName: "checklist")
            } trailing: {
                StatusBadge("\(tasks.count)", tone: tasks.isEmpty ? .neutral : .orange)
            }
        }
    }
}
