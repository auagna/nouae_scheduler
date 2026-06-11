import SwiftUI

struct PlanMonthView: View {
    let selectedDate: Date
    let blocks: [WorkBlock]
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        AppPanel(title: "Month Assembly", subtitle: "월간 배치 밀도를 보고 날짜를 선택하면 Day 배치판으로 이동합니다.") {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdayTitles, id: \.self) { title in
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(monthDates, id: \.self) { date in
                    Button {
                        onSelectDate(date)
                    } label: {
                        dayCell(date)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let dayBlocks = blocks.filter { calendar.isDate($0.startAt, inSameDayAs: date) }
        let completed = dayBlocks.filter { $0.executionState == .completed }.count
        let delayed = dayBlocks.filter { $0.executionState == .delayed }.count
        let isCurrentMonth = calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
        return VStack(alignment: .leading, spacing: 5) {
            Text(date.formatted(.dateTime.day()))
                .font(.caption.weight(.semibold))
                .foregroundStyle(isCurrentMonth ? Color.primary : Color.secondary.opacity(0.5))
            Spacer(minLength: 4)
            if !dayBlocks.isEmpty {
                HStack(spacing: 4) {
                    Circle().fill(Color.accentColor).frame(width: 5, height: 5)
                    Text("\(dayBlocks.count)")
                        .font(.caption2)
                    if completed > 0 {
                        Text("✓\(completed)").font(.caption2).foregroundStyle(.green)
                    }
                    if delayed > 0 {
                        Text("↷\(delayed)").font(.caption2).foregroundStyle(.orange)
                    }
                }
            }
        }
        .frame(minHeight: 68, alignment: .topLeading)
        .padding(8)
        .background(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.accentColor.opacity(0.12) : Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var weekdayTitles: [String] {
        calendar.shortWeekdaySymbols
    }

    private var monthDates: [Date] {
        guard let month = calendar.dateInterval(of: .month, for: selectedDate),
              let firstWeek = calendar.dateInterval(of: .weekOfYear, for: month.start) else {
            return []
        }
        let end = calendar.dateInterval(of: .weekOfYear, for: month.end.addingTimeInterval(-1))?.end ?? month.end
        var dates: [Date] = []
        var cursor = firstWeek.start
        while cursor < end {
            dates.append(cursor)
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? end
        }
        return dates
    }
}
