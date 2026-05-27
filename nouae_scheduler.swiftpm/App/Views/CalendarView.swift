import SwiftUI

struct CalendarView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @ObservedObject var selectionStore: CalendarSelectionStore

    @State private var selectedDate = Date()
    @State private var sources: [CalendarSource] = []
    @State private var events: [CalendarEvent] = []
    @State private var isLoading = false
    @State private var isShowingFilter = false
    @State private var errorMessage: String?
    @State private var showsPermissionAction = false

    var body: some View {
        VStack(spacing: 0) {
            dateHeader
                .padding(.horizontal)
                .padding(.vertical, 10)

            if let errorMessage {
                VStack(spacing: 10) {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if showsPermissionAction {
                        Button("캘린더 권한 요청") {
                            Task { await requestPermissionAndReload() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }

            if isLoading {
                ProgressView("일정 불러오는 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if events.isEmpty && errorMessage == nil {
                ContentUnavailableView("선택한 캘린더에 일정이 없습니다.", systemImage: "calendar.badge.exclamationmark")
            } else {
                List(events) { event in
                    CalendarEventRow(event: event)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Calendar")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingFilter = true } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                    .disabled(sources.isEmpty)
            }
        }
        .sheet(isPresented: $isShowingFilter) {
            NavigationStack {
                CalendarFilterSheet(
                    sources: $sources,
                    selectionStore: selectionStore,
                    onSelectionChanged: { Task { await loadEventsForSelectedDate() } }
                )
            }
        }
        .task { await loadCalendarsAndEvents() }
    }

    private var dateHeader: some View {
        HStack(spacing: 12) {
            Button { moveDate(by: -1) } label: { Image(systemName: "chevron.left").frame(width: 34, height: 34) }
                .buttonStyle(.bordered)

            VStack(spacing: 2) {
                Text(dateTitle(selectedDate)).font(.headline)
                Text(weekdayTitle(selectedDate)).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button { moveDate(by: 1) } label: { Image(systemName: "chevron.right").frame(width: 34, height: 34) }
                .buttonStyle(.bordered)
        }
    }

    private func moveDate(by value: Int) {
        selectedDate = Foundation.Calendar.current.date(byAdding: .day, value: value, to: selectedDate) ?? selectedDate
        Task { await loadEventsForSelectedDate() }
    }

    private func requestPermissionAndReload() async {
        do {
            try await eventKitManager.requestCalendarAccess()
            await loadCalendarsAndEvents()
        } catch {
            errorMessage = error.localizedDescription
            showsPermissionAction = true
        }
    }

    private func loadCalendarsAndEvents() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedSources = try await eventKitManager.fetchCalendars()
            sources = selectionStore.applySelection(to: fetchedSources)
            errorMessage = nil
            showsPermissionAction = false
            await loadEventsForSelectedDate()
        } catch {
            events = []
            errorMessage = error.localizedDescription
            showsPermissionAction = true
        }
    }

    private func loadEventsForSelectedDate() async {
        do {
            let start = Foundation.Calendar.current.startOfDay(for: selectedDate)
            let end = Foundation.Calendar.current.date(byAdding: .day, value: 1, to: start) ?? selectedDate
            let selectedIds = selectionStore.selectedIds(from: sources)
            events = try await eventKitManager.fetchEvents(from: start, to: end, calendarIds: selectedIds)
            errorMessage = nil
            showsPermissionAction = false
        } catch {
            events = []
            errorMessage = error.localizedDescription
            showsPermissionAction = true
        }
    }

    private func dateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func weekdayTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
