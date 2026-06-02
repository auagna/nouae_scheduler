import SwiftData
import SwiftUI

enum CalendarViewType: String, CaseIterable, Identifiable { case day = "Day", week = "Week", month = "Month"; var id: String { rawValue } }

struct CalendarView: View {
    @EnvironmentObject private var services: AppServices
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @AppStorage("selectedProjectCalendarIds") private var storedCalendarIds = ""
    @State private var viewType: CalendarViewType = .month
    @State private var selectedDate = Date()
    @State private var events: [CalendarEventSnapshot] = []
    @State private var selectedCalendarIds: Set<String> = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("보기", selection: $viewType) { ForEach(CalendarViewType.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).padding()
                HStack { Button { move(-1) } label: { Image(systemName: "chevron.left") }; Spacer(); DatePicker("기준 날짜", selection: $selectedDate, displayedComponents: .date).labelsHidden(); Spacer(); Button { move(1) } label: { Image(systemName: "chevron.right") } }.padding(.horizontal).padding(.bottom, 8)
                if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red).padding(.bottom, 6) }
                CalendarFlowBoard(viewType: viewType, date: selectedDate, events: events)
            }
            .navigationTitle("Calendar").toolbar { filterMenu }
            .task { restoreFilter(); await loadEvents() }
            .onChange(of: selectedDate) { reload() }.onChange(of: viewType) { reload() }
        }
    }

    private var filterMenu: some ToolbarContent { ToolbarItem(placement: .topBarTrailing) { Menu { Button("전체 선택") { selectedCalendarIds = Set(projects.compactMap(\.calendarIdentifier)); persistAndReload() }; Button("전체 해제") { selectedCalendarIds = []; persistAndReload() }; Divider(); ForEach(projects.filter { $0.calendarIdentifier != nil }) { project in Toggle(project.title, isOn: selectionBinding(project)) } } label: { Image(systemName: "line.3.horizontal.decrease.circle") } } }
    private func selectionBinding(_ project: Project) -> Binding<Bool> { Binding(get: { project.calendarIdentifier.map(selectedCalendarIds.contains) ?? false }, set: { enabled in guard let id = project.calendarIdentifier else { return }; if enabled { selectedCalendarIds.insert(id) } else { selectedCalendarIds.remove(id) }; persistAndReload() }) }
    private func restoreFilter() { if storedCalendarIds == "__none__" { selectedCalendarIds = [] } else { let saved = Set(storedCalendarIds.split(separator: ",").map(String.init)); selectedCalendarIds = saved.isEmpty ? Set(projects.compactMap(\.calendarIdentifier)) : saved } }
    private func persistAndReload() { storedCalendarIds = selectedCalendarIds.isEmpty ? "__none__" : selectedCalendarIds.sorted().joined(separator: ","); reload() }
    private func reload() { Task { await loadEvents() } }
    private func move(_ value: Int) { let component: Calendar.Component = viewType == .day ? .day : viewType == .week ? .weekOfYear : .month; selectedDate = Calendar.current.date(byAdding: component, value: value, to: selectedDate) ?? selectedDate }
    private func loadEvents() async { let calendar = Calendar.current; let interval: DateInterval; switch viewType { case .day: interval = DateSnapper.dayInterval(for: selectedDate); case .week: interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) ?? DateSnapper.dayInterval(for: selectedDate); case .month: interval = calendar.dateInterval(of: .month, for: selectedDate) ?? DateSnapper.dayInterval(for: selectedDate) }; do { events = try await services.calendarSyncManager.fetchEvents(from: interval.start, to: interval.end, calendarIds: selectedCalendarIds); errorMessage = nil } catch { errorMessage = error.localizedDescription } }
}

struct CalendarFlowBoard: View {
    let viewType: CalendarViewType
    let date: Date
    let events: [CalendarEventSnapshot]
    var body: some View { switch viewType { case .day: dayView; case .week: weekView; case .month: monthView } }
    private var dayView: some View { List(events) { event in eventRow(event) }.overlay { if events.isEmpty { ContentUnavailableView("일정 없음", systemImage: "calendar", description: Text("선택한 캘린더에 일정이 없습니다.")) } } }
    private var weekView: some View { ScrollView(.horizontal) { HStack(alignment: .top, spacing: 8) { ForEach(daysInWeek, id: \.self) { day in VStack(alignment: .leading, spacing: 8) { Text(day.formatted(.dateTime.weekday(.abbreviated).day())).font(.caption.weight(.semibold)); ForEach(eventsForDay(day).prefix(5)) { event in Text(event.title).font(.caption2).lineLimit(2).padding(6).frame(maxWidth: .infinity, alignment: .leading).background(Color(calendarHex: event.colorHex).opacity(0.18), in: RoundedRectangle(cornerRadius: 6)) } }.frame(width: 132, alignment: .topLeading).padding(8) } }.padding(.horizontal) } }
    private var monthView: some View { ScrollView { VStack(spacing: 4) { LazyVGrid(columns: monthColumns) { ForEach(Calendar.current.veryShortWeekdaySymbols, id: \.self) { Text($0).font(.caption2).foregroundStyle(.secondary) } }; LazyVGrid(columns: monthColumns, spacing: 1) { ForEach(Array(monthCells.enumerated()), id: \.offset) { _, day in if let day { monthCell(day) } else { Color.clear.frame(minHeight: 82) } } } }.padding(.horizontal) } }
    private var monthColumns: [GridItem] { Array(repeating: GridItem(.flexible(), alignment: .top), count: 7) }
    private func monthCell(_ day: Date) -> some View { VStack(alignment: .leading, spacing: 3) { Text(day.formatted(.dateTime.day())).font(.caption.weight(Calendar.current.isDateInToday(day) ? .bold : .regular)); ForEach(eventsForDay(day).prefix(3)) { event in Text(event.title).font(.caption2).lineLimit(1).padding(.horizontal, 3).padding(.vertical, 2).frame(maxWidth: .infinity, alignment: .leading).background(Color(calendarHex: event.colorHex).opacity(0.22), in: RoundedRectangle(cornerRadius: 3)) } }.frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading).padding(5).overlay(Rectangle().stroke(.quaternary, lineWidth: 0.5)) }
    private var daysInWeek: [Date] { let start = Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date; return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) } }
    private var monthCells: [Date?] { guard let interval = Calendar.current.dateInterval(of: .month, for: date), let range = Calendar.current.range(of: .day, in: .month, for: date) else { return [] }; let prefix = max(Calendar.current.component(.weekday, from: interval.start) - 1, 0); return Array(repeating: nil, count: prefix) + range.map { Calendar.current.date(byAdding: .day, value: $0 - 1, to: interval.start) } }
    private func eventsForDay(_ day: Date) -> [CalendarEventSnapshot] { events.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) } }
    private func eventRow(_ event: CalendarEventSnapshot) -> some View { HStack(alignment: .top) { Circle().fill(Color(calendarHex: event.colorHex)).frame(width: 10, height: 10).padding(.top, 5); VStack(alignment: .leading) { Text(event.title); Text(event.startAt.formatted(date: .omitted, time: .shortened) + " - " + event.endAt.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(.secondary); Text(event.calendarTitle).font(.caption2).foregroundStyle(.secondary) } } }
}
