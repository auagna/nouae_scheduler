import EventKit
import Foundation
import SwiftData
import SwiftUI

enum CalendarViewType: String, CaseIterable, Identifiable {
    case canvas = "Canvas"
    case month = "Month"
    case week = "Week"
    case day = "Day"

    var id: String { rawValue }
}

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var services: AppServices
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]

    @AppStorage("nouae.sharedSelectedDate") private var sharedSelectedDateTime: Double = Date().timeIntervalSinceReferenceDate
    @State private var viewType: CalendarViewType = .month
    @State private var selectedDate = Date()
    @State private var calendars: [CalendarSource] = []
    @State private var selectedCalendarIds: Set<String> = []
    @State private var items: [CalendarTimelineItem] = []
    @State private var showingFilter = false
    @State private var isDrawingMode = false
    @State private var selectedItem: CalendarTimelineItem?
    @State private var editingItem: CalendarTimelineItem?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let selectionKey = "nouae.calendar.selected.ids"

    var body: some View {
        NavigationStack {
            AppScreenContainer(scrolls: false, spacing: 12) {
                CalendarHeader(
                    subtitle: titleText,
                    syncTone: errorMessage == nil ? .green : .orange,
                    isDrawingMode: $isDrawingMode,
                    showsDrawingToggle: viewType == .canvas,
                    onToday: goToday,
                    onFilter: { showingFilter = true }
                )

                CalendarViewTypePicker(selection: $viewType)
                    .onChange(of: viewType) { _, _ in
                        if viewType != .canvas { isDrawingMode = false }
                        Task { await loadItems() }
                    }

                dateNavigation

                if let errorMessage {
                    permissionPanel(errorMessage)
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    content
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingFilter) { filterSheet }
            .sheet(item: $selectedItem) { item in
                CalendarEventDetailSheet(
                    item: item,
                    project: project(for: item),
                    onOpenProject: { selectedItem = nil },
                    onEdit: {
                        selectedItem = nil
                        editingItem = item
                    },
                    onDelete: {
                        selectedItem = nil
                        Task { await delete(item: item) }
                    },
                    onImportAsWorkBlock: {
                        selectedItem = nil
                        importAsWorkBlock(item)
                    }
                )
            }
            .sheet(item: $editingItem) { item in
                CalendarEventEditSheet(item: item) { title, startAt, endAt in
                    Task { await update(item: item, title: title, startAt: startAt, endAt: endAt) }
                }
            }
            .task {
                syncSelectedDateFromShared()
                await loadAll()
            }
            .onChange(of: selectedDate) { _, newValue in
                sharedSelectedDateTime = Calendar.current.startOfDay(for: newValue).timeIntervalSinceReferenceDate
            }
            .onChange(of: sharedSelectedDateTime) { _, _ in
                syncSelectedDateFromShared()
                Task { await loadItems() }
            }
        }
    }

    private var dateNavigation: some View {
        HStack(spacing: 12) {
            Button { moveDate(-1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)

            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.headline)
                Text(viewType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { moveDate(1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewType {
        case .canvas:
            CalendarCanvasView(
                selectedDate: $selectedDate,
                items: items,
                projects: projects,
                isDrawingMode: isDrawingMode,
                onSelectDay: { day in
                    selectedDate = day
                    viewType = .day
                    Task { await loadItems() }
                },
                onSelectEvent: { selectedItem = $0 }
            )
        case .month:
            CalendarMonthView(
                selectedDate: $selectedDate,
                monthDates: monthGridDates,
                weekdayTitles: weekdayTitles,
                itemsForDay: itemsForDay,
                onSelectDay: { day in
                    selectedDate = day
                    viewType = .day
                    Task { await loadItems() }
                },
                onSelectEvent: { selectedItem = $0 }
            )
        case .week:
            CalendarWeekView(
                weekDates: weekDates,
                itemsForDay: itemsForDay,
                onSelectEvent: { selectedItem = $0 }
            )
        case .day:
            CalendarDayView(
                date: selectedDate,
                items: itemsForDay(selectedDate),
                localBlocks: blocks.filter { Calendar.current.isDate($0.startAt, inSameDayAs: selectedDate) },
                onSelectEvent: { selectedItem = $0 }
            )
        }
    }

    private var filterSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button("전체 선택") {
                        selectedCalendarIds = Set(calendars.map(\.id))
                        persistSelection()
                        Task { await loadItems() }
                    }
                    Button("전체 해제") {
                        selectedCalendarIds = []
                        persistSelection()
                        Task { await loadItems() }
                    }
                }

                Section("Project Calendar") {
                    ForEach(calendars) { calendar in
                        Toggle(isOn: binding(for: calendar.id)) {
                            HStack {
                                Circle()
                                    .fill(Color(calendarHex: calendar.colorHex))
                                    .frame(width: 10, height: 10)
                                Text(calendar.title)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendar Filter")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { showingFilter = false }
                }
            }
        }
    }

    private func permissionPanel(_ message: String) -> some View {
        ContentUnavailableView(
            "Calendar 접근 필요",
            systemImage: "calendar.badge.exclamationmark",
            description: Text(message)
        )
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
        let component: Calendar.Component
        switch viewType {
        case .canvas, .month: component = .month
        case .week: component = .weekOfYear
        case .day: component = .day
        }
        selectedDate = Calendar.current.date(byAdding: component, value: amount, to: selectedDate) ?? selectedDate
        Task { await loadItems() }
    }

    private func goToday() {
        selectedDate = Date()
        Task { await loadItems() }
    }

    private func syncSelectedDateFromShared() {
        let sharedDate = Date(timeIntervalSinceReferenceDate: sharedSelectedDateTime)
        if !Calendar.current.isDate(sharedDate, inSameDayAs: selectedDate) {
            selectedDate = sharedDate
        }
    }

    private func update(item: CalendarTimelineItem, title: String, startAt: Date, endAt: Date) async {
        guard let identifier = item.externalEventIdentifier else { return }
        do {
            try await services.calendarSync.updateEvent(identifier: identifier, title: title, startAt: startAt, endAt: endAt)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(item: CalendarTimelineItem) async {
        guard let identifier = item.externalEventIdentifier else { return }
        do {
            try await services.calendarSync.deleteEvent(identifier: identifier)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importAsWorkBlock(_ item: CalendarTimelineItem) {
        guard item.workBlockId == nil else { return }
        do {
            let project = project(for: item)
            let block = try stores.workBlockStore.createWorkBlock(
                title: item.title,
                projectId: project?.id,
                startAt: item.startAt,
                endAt: item.endAt
            )
            block.calendarIdentifier = item.calendarIdentifier
            block.eventIdentifier = item.externalEventIdentifier
            block.syncState = .synced
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var dateRange: DateInterval {
        switch viewType {
        case .canvas, .month:
            return Calendar.current.dateInterval(of: .month, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 86400)
        case .week:
            return Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 86400 * 7)
        case .day:
            return Calendar.current.dateInterval(of: .day, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 86400)
        }
    }

    private var titleText: String {
        switch viewType {
        case .canvas, .month:
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

    private func project(for item: CalendarTimelineItem) -> Project? {
        projects.first { $0.id == item.projectId || $0.calendarIdentifier == item.calendarIdentifier }
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
