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
    @Environment(\.colorScheme) private var colorScheme

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
                    .foregroundStyle(dayTextColor)
                    .frame(width: 25, height: 25)
                    .background(dayMarkerBackground, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(todayRingColor, lineWidth: Calendar.current.isDateInToday(day) && !isSelected ? 1.4 : 0)
                    }

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
            .background(cellBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(separatorColor, lineWidth: 1)
            }
            .opacity(isCurrentMonth ? 1 : 0.58)
        }
        .buttonStyle(.plain)
    }

    private var dayTextColor: Color {
        if isSelected { return .accentColor }
        return isCurrentMonth ? .primary : .secondary
    }

    private var dayMarkerBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.24 : 0.18)
        }
        if Calendar.current.isDateInToday(day) {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.12 : 0.08)
        }
        return .clear
    }

    private var cellBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.10 : 0.07)
        }
        if colorScheme == .dark {
            return Color.white.opacity(0.045)
        }
        return Color(uiColor: .secondarySystemBackground)
    }

    private var separatorColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.13) : Color.black.opacity(0.09)
    }

    private var todayRingColor: Color {
        Color.accentColor.opacity(colorScheme == .dark ? 0.95 : 0.85)
    }
}
