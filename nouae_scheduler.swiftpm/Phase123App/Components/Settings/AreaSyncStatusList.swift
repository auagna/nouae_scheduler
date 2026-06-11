import SwiftUI

struct AreaSyncStatusList: View {
    let areas: [ProjectArea]

    var body: some View {
        AppPanel(title: "Area Sync Status", subtitle: "Area는 Apple Calendar + Apple Reminder List와 연결됩니다.") {
            if areas.isEmpty {
                Text("Area가 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(areas) { area in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color(calendarHex: area.calendarColorHex))
                                .frame(width: 9, height: 9)
                            Text(area.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            SyncStatusBadge(state: area.syncState)
                        }
                        HStack {
                            StatusBadge(area.calendarIdentifier == nil ? "Calendar missing" : "Calendar linked", tone: area.calendarIdentifier == nil ? .orange : .green)
                            StatusBadge(area.reminderListIdentifier == nil ? "Reminder missing" : "Reminder linked", tone: area.reminderListIdentifier == nil ? .orange : .green)
                        }
                        AppDivider()
                    }
                }
            }
        }
    }
}
