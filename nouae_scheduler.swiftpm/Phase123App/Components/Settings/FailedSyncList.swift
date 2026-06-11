import SwiftUI

struct FailedSyncList: View {
    let blocks: [WorkBlock]
    let tasks: [RawTask]
    let projects: [Project]
    let onRetryAll: () -> Void

    var body: some View {
        AppPanel(title: "Failed Sync", subtitle: "실패한 동기화는 숨기지 않습니다. 다시 시도하거나 연결 상태를 확인합니다.") {
            if blocks.isEmpty && tasks.isEmpty && projects.isEmpty {
                Text("실패한 동기화 항목이 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(blocks.prefix(5)) { block in
                    AppListRow(title: block.title, subtitle: "Calendar Event failed") {
                        Image(systemName: "calendar.badge.exclamationmark")
                    } trailing: {
                        SyncStatusBadge(state: block.syncState)
                    }
                }
                ForEach(tasks.prefix(5)) { task in
                    AppListRow(title: task.title, subtitle: "Reminder failed") {
                        Image(systemName: "exclamationmark.bubble")
                    } trailing: {
                        SyncStatusBadge(state: task.syncState)
                    }
                }
                ForEach(projects.prefix(5)) { project in
                    AppListRow(title: project.title, subtitle: "Project / Area link attention") {
                        Image(systemName: "folder.badge.gearshape")
                    } trailing: {
                        SyncStatusBadge(state: project.syncState)
                    }
                }
            }
            Button("Retry Failed", action: onRetryAll)
                .buttonStyle(.borderedProminent)
                .disabled(blocks.isEmpty && tasks.isEmpty)
        }
    }
}
