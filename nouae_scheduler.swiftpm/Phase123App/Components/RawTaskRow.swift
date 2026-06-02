import SwiftUI

struct RawTaskRow: View {
    let task: RawTask
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .foregroundStyle(.primary)
                    SyncStatusBadge(state: task.syncState)
                }
                Spacer()
                Image(systemName: "calendar.badge.plus")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .draggable(task.id.uuidString)
    }
}
