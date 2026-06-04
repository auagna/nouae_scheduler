import SwiftUI

struct CalendarMonthView: View {
    @Binding var selectedDate: Date
    let monthDates: [Date]
    let weekdayTitles: [String]
    let itemsForDay: (Date) -> [CalendarTimelineItem]
    let onSelectDay: (Date) -> Void
    let onSelectEvent: (CalendarTimelineItem) -> Void

    var body: some View {
        AppPanel(title: "Month", subtitle: "날짜 grid와 compact event indicators") {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(weekdayTitles, id: \.self) { title in
                        Text(title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(monthDates, id: \.self) { day in
                        CalendarMonthDayCell(
                            day: day,
                            isCurrentMonth: Calendar.current.isDate(day, equalTo: selectedDate, toGranularity: .month),
                            isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                            items: itemsForDay(day),
                            onSelectDay: { onSelectDay(day) },
                            onSelectEvent: onSelectEvent
                        )
                    }
                }
            }
        }
    }
}

private struct CalendarMonthDayCell: View {
    let day: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let items: [CalendarTimelineItem]
    let onSelectDay: () -> Void
    let onSelectEvent: (CalendarTimelineItem) -> Void

    var body: some View {
        Button(action: onSelectDay) {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.caption.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isCurrentMonth ? Color.primary : Color.secondary)

                ForEach(items.prefix(3)) { item in
                    Button { onSelectEvent(item) } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(calendarHex: item.colorHex))
                                .frame(width: 5, height: 5)
                            Text(item.title)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if items.count > 3 {
                    Text("+\(items.count - 3)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(7)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(isSelected ? Color.accentColor.opacity(0.14) : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
