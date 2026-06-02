import SwiftUI

struct ProjectCard: View {
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(calendarHex: project.calendarColorHex))
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 3) {
                Text(project.title).font(.headline)
                Text(project.type.title + " · " + project.status.title)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: project.calendarIdentifier == nil ? "calendar.badge.exclamationmark" : "calendar.badge.checkmark")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SyncStatusBadge: View {
    let state: SyncState

    var body: some View {
        Label(state.title, systemImage: icon)
            .font(.caption2)
            .foregroundStyle(color)
    }

    private var icon: String {
        switch state {
        case .local: return "iphone"
        case .pending: return "clock"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }

    private var color: Color {
        switch state {
        case .failed: return .red
        case .pending, .syncing: return .orange
        case .synced: return .green
        case .local: return .secondary
        }
    }
}

struct WorkBlockSummaryRow: View {
    let block: WorkBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.title).font(.headline)
            Text(block.startAt.formatted(date: .omitted, time: .shortened) + " - " + block.endAt.formatted(date: .omitted, time: .shortened))
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Text(block.executionState.title).font(.caption2).foregroundStyle(.secondary)
                SyncStatusBadge(state: block.syncState)
            }
        }
    }
}
