import SwiftUI

struct CalendarCanvasGrid: View {
    let selectedDate: Date
    let items: [CalendarTimelineItem]
    let zoomScale: CGFloat
    let onSelectDay: (Date) -> Void
    let onSelectEvent: (CalendarTimelineItem) -> Void

    private var dates: [Date] {
        guard let month = Calendar.current.dateInterval(of: .month, for: selectedDate) else { return [] }
        let firstWeekday = Calendar.current.component(.weekday, from: month.start)
        let leading = (firstWeekday - Calendar.current.firstWeekday + 7) % 7
        let gridStart = Calendar.current.date(byAdding: .day, value: -leading, to: month.start) ?? month.start
        return (0..<42).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: gridStart) }
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }

            ForEach(dates, id: \.self) { day in
                CalendarCanvasDayCell(
                    day: day,
                    isCurrentMonth: Calendar.current.isDate(day, equalTo: selectedDate, toGranularity: .month),
                    items: itemsForDay(day),
                    zoomLevel: zoomLevel,
                    onSelectDay: { onSelectDay(day) },
                    onSelectEvent: onSelectEvent
                )
            }
        }
        .padding(14)
    }

    private var zoomLevel: CalendarCanvasZoomLevel {
        if zoomScale >= 1.15 { return .high }
        if zoomScale >= 0.85 { return .medium }
        return .low
    }

    private func itemsForDay(_ day: Date) -> [CalendarTimelineItem] {
        items.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) }
    }
}

enum CalendarCanvasZoomLevel {
    case high
    case medium
    case low
}

private struct CalendarCanvasDayCell: View {
    let day: Date
    let isCurrentMonth: Bool
    let items: [CalendarTimelineItem]
    let zoomLevel: CalendarCanvasZoomLevel
    let onSelectDay: () -> Void
    let onSelectEvent: (CalendarTimelineItem) -> Void

    var body: some View {
        Button(action: onSelectDay) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isCurrentMonth ? Color.primary : Color.secondary)
                    Spacer()
                    if zoomLevel != .high, !items.isEmpty {
                        Text("\(items.count)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                switch zoomLevel {
                case .high:
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
                case .medium:
                    CalendarDensityDots(items: items)
                case .low:
                    CalendarDensityBar(items: items)
                }

                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppUI.separatorColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct CalendarDensityDots: View {
    let items: [CalendarTimelineItem]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(items.prefix(8)) { item in
                Circle()
                    .fill(Color(calendarHex: item.colorHex))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

private struct CalendarDensityBar: View {
    let items: [CalendarTimelineItem]

    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.blue.opacity(items.isEmpty ? 0.08 : min(0.75, 0.15 + Double(items.count) * 0.08)))
                .frame(width: proxy.size.width, height: 6)
        }
        .frame(height: 8)
    }
}
