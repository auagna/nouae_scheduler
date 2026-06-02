import Combine
import EventKit
import Foundation
import SwiftData

struct CalendarEventSnapshot: Identifiable {
    let id: String
    let title: String
    let startAt: Date
    let endAt: Date
    let calendarIdentifier: String
    let calendarTitle: String
    let colorHex: String?
}

@MainActor
final class CalendarSyncManager: ObservableObject {
    private let eventKit: EventKitManager
    private let projectStore: ProjectStore
    private let modelContext: ModelContext
    private var pendingSyncTasks: [UUID: Task<Void, Never>] = [:]

    @Published private(set) var lastErrorMessage: String?

    init(eventKit: EventKitManager, projectStore: ProjectStore, modelContext: ModelContext) {
        self.eventKit = eventKit
        self.projectStore = projectStore
        self.modelContext = modelContext
    }

    func createCalendarForProject(_ project: Project) async throws {
        try await eventKit.requireCalendarAccess()
        guard let source = eventKit.sourceForNewCalendar() else { throw SyncError.missingCalendarSource }
        let calendar = EKCalendar(for: .event, eventStore: eventKit.eventStore)
        calendar.title = project.title
        calendar.source = source
        try eventKit.eventStore.saveCalendar(calendar, commit: true)
        try projectStore.updateCalendarLink(project: project, calendarIdentifier: calendar.calendarIdentifier, calendarTitle: calendar.title, calendarColorHex: eventKit.calendarColorHex(calendar))
    }

    func scheduleWorkBlockSync(_ block: WorkBlock) {
        pendingSyncTasks[block.id]?.cancel()
        block.syncState = .pending
        block.updatedAt = .now
        try? modelContext.save()
        pendingSyncTasks[block.id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.syncWorkBlock(block)
        }
    }

    func syncWorkBlock(_ block: WorkBlock) async {
        do {
            try await eventKit.requireCalendarAccess()
            guard block.endAt > block.startAt else { throw SyncError.invalidTimeRange }
            guard let calendarIdentifier = block.calendarIdentifier,
                  let calendar = eventKit.calendar(identifier: calendarIdentifier) else { throw SyncError.missingProjectCalendar }
            block.syncState = .syncing
            try modelContext.save()
            let event = block.eventIdentifier.flatMap(eventKit.eventStore.event(withIdentifier:)) ?? EKEvent(eventStore: eventKit.eventStore)
            event.calendar = calendar
            event.title = block.title
            event.startDate = block.startAt
            event.endDate = block.endAt
            event.notes = block.memo.isEmpty ? nil : block.memo
            try eventKit.eventStore.save(event, span: .thisEvent, commit: true)
            block.eventIdentifier = event.eventIdentifier
            block.calendarIdentifier = calendar.calendarIdentifier
            block.syncState = .synced
            block.updatedAt = .now
            try modelContext.save()
            lastErrorMessage = nil
        } catch {
            block.syncState = .failed
            block.updatedAt = .now
            try? modelContext.save()
            lastErrorMessage = error.localizedDescription
        }
    }

    func reconcileLinkedWorkBlocksFromApple() async throws {
        try await eventKit.requireCalendarAccess()
        let blocks = try modelContext.fetch(FetchDescriptor<WorkBlock>())
        for block in blocks {
            guard let identifier = block.eventIdentifier else { continue }
            guard let event = eventKit.eventStore.event(withIdentifier: identifier) else {
                block.syncState = .failed
                continue
            }
            block.title = event.title ?? block.title
            block.startAt = event.startDate
            block.endAt = event.endDate
            block.calendarIdentifier = event.calendar.calendarIdentifier
            block.syncState = .synced
            block.updatedAt = .now
        }
        try modelContext.save()
    }

    func archiveProjectsWithMissingCalendars() async throws {
        try await eventKit.requireCalendarAccess()
        let calendarIds = Set(eventKit.availableEventCalendars().map(\.calendarIdentifier))
        for project in try projectStore.fetchActiveProjects() {
            guard let identifier = project.calendarIdentifier else { continue }
            if !calendarIds.contains(identifier) { try projectStore.archiveProjectForBrokenCalendarLink(project) }
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date, calendarIds: Set<String>) async throws -> [CalendarEventSnapshot] {
        try await eventKit.requireCalendarAccess()
        let calendars = eventKit.availableEventCalendars().filter { calendarIds.isEmpty || calendarIds.contains($0.calendarIdentifier) }
        let predicate = eventKit.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventKit.eventStore.events(matching: predicate).map { event in
            CalendarEventSnapshot(id: event.eventIdentifier ?? UUID().uuidString, title: event.title ?? "제목 없음", startAt: event.startDate, endAt: event.endDate, calendarIdentifier: event.calendar.calendarIdentifier, calendarTitle: event.calendar.title, colorHex: eventKit.calendarColorHex(event.calendar))
        }.sorted { $0.startAt < $1.startAt }
    }
}
