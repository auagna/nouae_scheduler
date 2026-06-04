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
                        CalendarEventCompactRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
