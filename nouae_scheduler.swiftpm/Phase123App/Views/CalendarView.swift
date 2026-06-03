import Foundation
import SwiftData
import SwiftUI

private enum CalendarViewMode: String, CaseIterable, Identifiable {
    case month = "Month"
    case week = "Week"
    case day = "Day"
    var id: String { rawValue }
}

struct CalendarView: View {
    @EnvironmentObject private var services: AppServices
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]

    @State private var mode: CalendarViewMode = .month
    @State private var selectedDate = Date()
    @State private var calendars: [CalendarSource] = []
    @State private var selectedCalendarIds: Set<String> = []
    @State private var items: [CalendarTimelineItem] = []
    @State private var showingFilter = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let selectionKey = "nouae.calendar.selected.ids"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                if let errorMessage {
                    permissionPanel(errorMessage)
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    content
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingFilter = true } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                        .accessibilityLabel("Calendar 필터")
                }
            }
            .sheet(isPresented: $showingFilter) { filterSheet }
            .task { await loadAll() }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Picker("보기", selection: $mode) {
                ForEach(CalendarViewMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            HStack {
                Button { moveDate(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(titleText)
                    .font(.headline)
                Spacer()
                Button { moveDate(1) } label: { Image(systemName: "chevron.right") }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .onChange(of: mode) { _, _ in Task { await loadItems() } }
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .month:
            monthView
        case .week:
            weekView
        case .day:
            dayView
        }
    }

    private var monthView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(weekdayTitles, id: \.self) { title in
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                ForEach(monthGridDates, id: \.self) { day in
                    CalendarMonthCell(
                        day: day,
                        isCurrentMonth: Calendar.current.isDate(day, equalTo: selectedDate, toGranularity: .month),
                        isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                        items: itemsForDay(day),
                        projects: projects
                    ) { selectedDate = day; mode = .day; Task { await loadItems() } }
                    .frame(minHeight: 104)
                }
            }
            .padding()
        }
    }

    private var weekView: some View {
        List {
            ForEach(weekDates, id: \.self) { day in
                Section(day.formatted(date: .abbreviated, time: .omitted)) {
                    rows(for: itemsForDay(day))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var dayView: some View {
        List {
            let dayItems = itemsForDay(selectedDate)
            if dayItems.isEmpty {
                ContentUnavailableView("일정이 없습니다", systemImage: "calendar", description: Text("선택한 Calendar 필터에 표시할 일정이 없습니다."))
            }
            rows(for: dayItems)
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func rows(for rowItems: [CalendarTimelineItem]) -> some View {
        if rowItems.isEmpty {
            Text("일정 없음")
                .foregroundStyle(.secondary)
        }
        ForEach(rowItems) { item in
            if let project = projects.first(where: { $0.id == item.projectId }) {
                NavigationLink { ProjectDashboardView(project: project) } label: { CalendarTimelineRow(item: item, projectTitle: project.title) }
            } else {
                CalendarTimelineRow(item: item, projectTitle: nil)
            }
        }
    }

    private var filterSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button("전체 선택") { selectedCalendarIds = Set(calendars.map(\.id)); persistSelection(); Task { await loadItems() } }
                    Button("전체 해제") { selectedCalendarIds = []; persistSelection(); Task { await loadItems() } }
                }
                Section("Project Calendar") {
                    ForEach(calendars) { calendar in
                        Toggle(isOn: binding(for: calendar.id)) {
                            HStack {
                                Circle().fill(Color(calendarHex: calendar.colorHex)).frame(width: 10, height: 10)
                                Text(calendar.title)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendar 필터")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { showingFilter = false } } }
        }
    }

    private func permissionPanel(_ message: String) -> some View {
        ContentUnavailableView("Calendar 접근 필요", systemImage: "calendar.badge.exclamationmark", description: Text(message))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            calendars = try await services.calendarSync.fetchCalendars()
            restoreSelectionIfNeeded()
            try await stores.projectStore.archiveProjectsWithMissingCalendars(calendarSyncManager: services.calendarSync)
            await loadItems()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadItems() async {
        let range = dateRange
        do {
            let external = try await services.calendarSync.fetchEvents(
                from: range.start,
                to: range.end,
                calendarIdentifiers: Array(selectedCalendarIds),
                projects: projects
            )
            let externalIds = Set(external.compactMap(\.externalEventIdentifier))
            let local = (try? stores.workBlockStore.fetchBlocks(from: range.start, to: range.end)) ?? []
            let localItems = local
                .filter { block in
                    guard let calendarIdentifier = block.calendarIdentifier else { return selectedCalendarIds.isEmpty }
                    return selectedCalendarIds.contains(calendarIdentifier)
                }
                .filter { block in
                    guard let eventIdentifier = block.eventIdentifier else { return true }
                    return !externalIds.contains(eventIdentifier)
                }
                .map { block in CalendarTimelineItem.local(block: block, project: projects.first { $0.id == block.projectId }) }
            items = (external + localItems).sorted { $0.startAt < $1.startAt }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveDate(_ amount: Int) {
        let component: Calendar.Component = mode == .month ? .month : mode == .week ? .weekOfYear : .day
        selectedDate = Calendar.current.date(byAdding: component, value: amount, to: selectedDate) ?? selectedDate
        Task { await loadItems() }
    }

    private var dateRange: DateInterval {
        switch mode {
        case .month:
            return Calendar.current.dateInterval(of: .month, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 86400)
        case .week:
            return Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 86400 * 7)
        case .day:
            return Calendar.current.dateInterval(of: .day, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 86400)
        }
    }

    private var titleText: String {
        switch mode {
        case .month:
            return selectedDate.formatted(.dateTime.year().month(.wide))
        case .week:
            let start = dateRange.start.formatted(.dateTime.month().day())
            let end = Calendar.current.date(byAdding: .day, value: -1, to: dateRange.end)?.formatted(.dateTime.month().day()) ?? ""
            return "\(start) - \(end)"
        case .day:
            return selectedDate.formatted(date: .abbreviated, time: .omitted)
        }
    }

    private var weekdayTitles: [String] {
        Calendar.current.shortWeekdaySymbols
    }

    private var monthGridDates: [Date] {
        guard let month = Calendar.current.dateInterval(of: .month, for: selectedDate) else { return [] }
        let firstWeekday = Calendar.current.component(.weekday, from: month.start)
        let leading = (firstWeekday - Calendar.current.firstWeekday + 7) % 7
        let gridStart = Calendar.current.date(byAdding: .day, value: -leading, to: month.start) ?? month.start
        return (0..<42).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private var weekDates: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: dateRange.start) }
    }

    private func itemsForDay(_ day: Date) -> [CalendarTimelineItem] {
        items.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { selectedCalendarIds.contains(id) },
            set: { isSelected in
                if isSelected { selectedCalendarIds.insert(id) }
                else { selectedCalendarIds.remove(id) }
                persistSelection()
                Task { await loadItems() }
            }
        )
    }

    private func restoreSelectionIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: selectionKey) == nil {
            let projectCalendarIds = Set(projects.compactMap(\.calendarIdentifier))
            let availableProjectIds = Set(calendars.map(\.id)).intersection(projectCalendarIds)
            selectedCalendarIds = availableProjectIds.isEmpty ? Set(calendars.map(\.id)) : availableProjectIds
            persistSelection()
            return
        }
        let raw = defaults.string(forKey: selectionKey) ?? ""
        selectedCalendarIds = Set(raw.split(separator: ",").map(String.init)).intersection(Set(calendars.map(\.id)))
    }

    private func persistSelection() {
        UserDefaults.standard.set(selectedCalendarIds.sorted().joined(separator: ","), forKey: selectionKey)
    }
}

private struct CalendarTimelineRow: View {
    let item: CalendarTimelineItem
    let projectTitle: String?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(calendarHex: item.colorHex))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                Text(item.startAt.formatted(date: .omitted, time: .shortened) + " - " + item.endAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let projectTitle {
                    Text(projectTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if item.isLocalOnly {
                    Text("Local WorkBlock")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

private struct CalendarMonthCell: View {
    let day: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let items: [CalendarTimelineItem]
    let projects: [Project]
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.caption.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isCurrentMonth ? Color.primary : Color.secondary)
                ForEach(items.prefix(3)) { item in
                    HStack(spacing: 4) {
                        Circle().fill(Color(calendarHex: item.colorHex)).frame(width: 5, height: 5)
                        Text(item.title)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                    }
                }
                if items.count > 3 {
                    Text("+\(items.count - 3)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(isSelected ? Color.accentColor.opacity(0.14) : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
