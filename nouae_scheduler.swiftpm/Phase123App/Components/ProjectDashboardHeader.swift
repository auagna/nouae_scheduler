import SwiftUI

struct ProjectDashboardHeader: View {
    let project: Project
    let onChangeStatus: (ProjectStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Circle().fill(Color(calendarHex: project.calendarColorHex)).frame(width: 14, height: 14); Text(project.title).font(.title2.bold()); Spacer(); Menu { ForEach(ProjectStatus.allCases) { status in Button(status.title) { onChangeStatus(status) } } } label: { Label(project.status.title, systemImage: "chevron.down.circle") } }
            Text(project.type.title).font(.subheadline).foregroundStyle(.secondary)
            HStack { Label(project.calendarTitle ?? "Calendar 미연결", systemImage: project.calendarIdentifier == nil ? "calendar.badge.exclamationmark" : "calendar.badge.checkmark").font(.caption); SyncStatusBadge(state: project.syncState) }
        }
        .padding(.vertical, 6)
    }
}
