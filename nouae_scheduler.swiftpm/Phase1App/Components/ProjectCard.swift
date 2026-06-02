import SwiftUI

struct ProjectCard: View {
    let project: Project

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(calendarHex: project.calendarColorHex))
                .frame(width: 12, height: 12)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 5) {
                Text(project.title)
                    .font(.headline)
                Text(project.type.title + " · " + project.status.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !project.goal.isEmpty {
                    Text(project.goal)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 10) {
                    Label(
                        project.calendarTitle ?? "Calendar 미연결",
                        systemImage: project.calendarIdentifier == nil ? "calendar.badge.exclamationmark" : "calendar.badge.checkmark"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    SyncStatusBadge(state: project.syncState)
                }
            }
        }
        .padding(.vertical, 5)
        .opacity(project.status == .archived ? 0.55 : 1)
    }
}
