import SwiftUI

struct CalendarWeekView: View {
    let weekDates: [Date]
    let itemsForDay: (Date) -> [CalendarTimelineItem]
    let onSelectEvent: (CalendarTimelineItem) -> Void

    var body: some View {
        AppPanel(title: "Week", subtitle: "7일 column과 시간 요약") {
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(weekDates, id: \.self) { day in
                        CalendarWeekColumn(day: day, items: itemsForDay(day), onSelectEvent: onSelectEvent)
                            .frame(width: 190)
                    }
                }
            }
        }
    }
}

private struct CalendarWeekColumn: View {
    let day: Date
    let items: [CalendarTimelineItem]
    let onSelectEvent: (CalendarTimelineItem) -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(day.formatted(.dateTime.month().day()))
                        .font(.headline)
                }

                AppDivider()

                if items.isEmpty {
                    Text("일정 없음")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }

                ForEach(items.prefix(10)) { item in
                    Button { onSelectEvent(item) } label: {
                        CalendarWeekEventChip(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private struct CalendarWeekEventChip: View {
    let item: CalendarTimelineItem

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(calendarHex: item.colorHex))
                .frame(width: 4)
                .frame(maxHeight: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(item.startAt.formatted(date: .omitted, time: .shortened) + " - " + item.endAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 64, alignment: .leading)
        .background(Color(calendarHex: item.colorHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color(calendarHex: item.colorHex).opacity(0.22), lineWidth: 1)
        }
    }
}
