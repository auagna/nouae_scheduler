import SwiftUI

struct CalendarDayView: View {
    let date: Date
    let items: [CalendarTimelineItem]
    let localBlocks: [WorkBlock]
    let onSelectEvent: (CalendarTimelineItem) -> Void
    let onAddItem: () -> Void

    var body: some View {
        AppPanel(title: "Day", subtitle: "Calendar events and Plan synced blocks") {
            ScrollView {
                VStack(alignment: .leading, spacing: AppUI.Spacing.card) {
                    HStack(alignment: .center, spacing: 10) {
                        AppSectionHeader(title: "Calendar Events", subtitle: date.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Button(action: onAddItem) {
                            Image(systemName: "plus")
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Add Calendar Item")
                    }

                    if items.isEmpty {
                        ContentUnavailableView("일정이 없습니다", systemImage: "calendar", description: Text("선택한 Calendar 필터에 표시할 일정이 없습니다."))
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(items) { item in
                        Button { onSelectEvent(item) } label: {
                            CalendarEventCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }

                    AppSectionHeader(title: "Plan Synced Blocks", subtitle: "nou ae WorkBlock")
                    ForEach(localBlocks) { block in
                        let timeText = "\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))"
                        AppListRow(
                            title: block.title,
                            subtitle: timeText
                        ) {
                            Image(systemName: "rectangle.fill")
                                .foregroundStyle(.blue)
                        } trailing: {
                            StatusBadge(block.executionState.title, tone: .neutral)
                        }
                    }
                }
            }
        }
    }
}

struct CalendarEventCompactRow: View {
    let item: CalendarTimelineItem

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(calendarHex: item.colorHex))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                Text(item.startAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CalendarEventCard: View {
    let item: CalendarTimelineItem

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(calendarHex: item.colorHex))
                    .frame(width: 5)
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                    Text("\(item.startAt.formatted(date: .omitted, time: .shortened)) - \(item.endAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if item.isLocalOnly {
                        StatusBadge("Local WorkBlock", tone: .orange)
                    }
                }
            }
        }
    }
}
