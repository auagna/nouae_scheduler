import SwiftUI

struct PlanWeekView: View {
    let selectedDate: Date
    let blocks: [WorkBlock]
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        AppPanel(title: "Week Assembly", subtitle: "7일 흐름을 보고 날짜를 선택하면 Day 배치판으로 들어갑니다.") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                ForEach(weekDates, id: \.self) { date in
                    Button {
                        onSelectDate(date)
                    } label: {
                        dayCard(date)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dayCard(_ date: Date) -> some View {
        let dayBlocks = blocks.filter { calendar.isDate($0.startAt, inSameDayAs: date) }
        let completed = dayBlocks.filter { $0.executionState == .completed }.count
        let delayed = dayBlocks.filter { $0.executionState == .delayed }.count
        return VStack(alignment: .leading, spacing: 8) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(date.formatted(.dateTime.day()))
                .font(.title3.weight(.semibold))
            Text("\(dayBlocks.count) blocks")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 5) {
                StatusBadge("\(completed) done", tone: .green)
                if delayed > 0 {
                    StatusBadge("\(delayed) delayed", tone: .orange)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(10)
        .background(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.accentColor.opacity(0.12) : Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var weekDates: [Date] {
        let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate)
        let start = interval?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}
