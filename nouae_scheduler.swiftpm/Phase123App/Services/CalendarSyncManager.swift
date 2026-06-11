import EventKit
import Foundation
import SwiftData
import UIKit

struct CalendarSource: Identifiable {
    let id: String
    let title: String
    let colorHex: String?
}

@MainActor
final class CalendarSyncManager {
    private let eventKit: EventKitManager
    private let context: ModelContext
    private var debounceTasks: [UUID: Task<Void, Never>] = [:]

    init(eventKit: EventKitManager, context: ModelContext) {
        self.eventKit = eventKit
        self.context = context
    }

    func fetchCalendars() async throws -> [CalendarSource] {
        try await eventKit.requireCalendarAccess()
        return eventKit.eventStore.calendars(for: .event)
            .map { CalendarSource(id: $0.calendarIdentifier, title: $0.title, colorHex: colorHex($0)) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func fetchEvents(from startDate: Date, to endDate: Date, calendarIdentifiers: [String], projects: [Project]) async throws -> [CalendarTimelineItem] {
        guard !calendarIdentifiers.isEmpty else { return [] }
        try await eventKit.requireCalendarAccess()
        let calendars = calendarIdentifiers.compactMap { eventKit.eventStore.calendar(withIdentifier: $0) }
        guard !calendars.isEmpty else { return [] }
        let predicate = eventKit.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventKit.eventStore.events(matching: predicate).map { event in
            let identifier = event.eventIdentifier ?? event.calendarItemIdentifier
            let project = projects.first { $0.calendarIdentifier == event.calendar.calendarIdentifier }
            return CalendarTimelineItem(
                id: "event-\(identifier)",
                title: event.title ?? "제목 없음",
                startAt: event.startDate,
                endAt: event.endDate,
                calendarIdentifier: event.calendar.calendarIdentifier,
                colorHex: colorHex(event.calendar),
                projectId: project?.id,
                workBlockId: nil,
                externalEventIdentifier: event.eventIdentifier,
                isLocalOnly: false
            )
        }
        .sorted { $0.startAt < $1.startAt }
    }

    func createCalendar(title: String) async throws -> CalendarSource {
        try await eventKit.requireCalendarAccess()
        if let existing = eventKit.eventStore.calendars(for: .event).first(where: { $0.title == title }) {
            return CalendarSource(id: existing.calendarIdentifier, title: existing.title, colorHex: colorHex(existing))
        }
        guard let source = preferredSource() else { throw SyncError.sourceNotFound }
        let calendar = EKCalendar(for: .event, eventStore: eventKit.eventStore)
        calendar.title = title
        calendar.source = source
        do {
            try eventKit.eventStore.saveCalendar(calendar, commit: true)
        } catch {
            throw SyncError.calendarCreationFailed
        }
        return CalendarSource(id: calendar.calendarIdentifier, title: calendar.title, colorHex: colorHex(calendar))
    }

    func ensureBlockCalendar() async throws -> CalendarSource {
        try await eventKit.requireCalendarAccess()
        let settings = try syncSettings()

        if let identifier = settings.blockCalendarIdentifier,
           let existing = eventKit.eventStore.calendar(withIdentifier: identifier) {
            settings.blockCalendarTitle = existing.title
            settings.updatedAt = Date()
            try? context.save()
            return CalendarSource(id: existing.calendarIdentifier, title: existing.title, colorHex: colorHex(existing))
        }

        if let existing = eventKit.eventStore.calendars(for: .event).first(where: { $0.title == settings.blockCalendarTitle }) {
            settings.blockCalendarIdentifier = existing.calendarIdentifier
            settings.blockCalendarTitle = existing.title
            settings.updatedAt = Date()
            try? context.save()
            return CalendarSource(id: existing.calendarIdentifier, title: existing.title, colorHex: colorHex(existing))
        }

        let created = try await createCalendar(title: settings.blockCalendarTitle)
        settings.blockCalendarIdentifier = created.id
        settings.blockCalendarTitle = created.title
        settings.updatedAt = Date()
        try context.save()
        return created
    }

    func scheduleSync(block: WorkBlock) {
        debounceTasks[block.id]?.cancel()
        block.syncState = .pending
        try? context.save()
        debounceTasks[block.id] = Task { [weak self, weak block] in
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled, let self, let block else { return }
            await self.sync(block: block)
            self.debounceTasks[block.id] = nil
        }
    }

    func refreshLinkedEvents() async throws {
        try await eventKit.requireCalendarAccess()
        for block in try context.fetch(FetchDescriptor<WorkBlock>()) {
            guard let identifier = block.eventIdentifier else { continue }
            guard let event = eventKit.eventStore.event(withIdentifier: identifier) else {
                block.syncState = .failed
                continue
            }
            block.title = event.title ?? block.title
            block.startAt = event.startDate
            block.endAt = event.endDate
            block.calendarIdentifier = event.calendar.calendarIdentifier
            block.memo = event.notes ?? ""
            block.updatedAt = Date()
            block.syncState = .synced
        }
        try context.save()
    }

    func updateEvent(identifier: String, title: String, startAt: Date, endAt: Date) async throws {
        try await eventKit.requireCalendarAccess()
        guard endAt > startAt else { throw SyncError.invalidTimeRange }
        guard let event = eventKit.eventStore.event(withIdentifier: identifier) else {
            throw SyncError.calendarNotFound
        }
        event.title = title
        event.startDate = startAt
        event.endDate = endAt
        try eventKit.eventStore.save(event, span: .thisEvent, commit: true)
    }

    @discardableResult
    func createEvent(
        title: String,
        location: String,
        isAllDay: Bool,
        startAt: Date,
        endAt: Date,
        calendarIdentifier: String?,
        projectId: UUID?,
        urlString: String,
        notes: String
    ) async throws -> String {
        try await eventKit.requireCalendarAccess()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw SyncError.invalidTitle }
        guard isAllDay || endAt > startAt else { throw SyncError.invalidTimeRange }

        let event = EKEvent(eventStore: eventKit.eventStore)
        event.title = trimmedTitle
        event.location = location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location
        event.isAllDay = isAllDay
        event.startDate = startAt
        event.endDate = endAt
        event.calendar = try await targetCalendar(projectId: projectId, calendarIdentifier: calendarIdentifier)
        event.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        if let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) {
            event.url = url
        }
        try eventKit.eventStore.save(event, span: .thisEvent, commit: true)
        return event.eventIdentifier ?? event.calendarItemIdentifier
    }

    func deleteEvent(identifier: String) async throws {
        try await eventKit.requireCalendarAccess()
        guard let event = eventKit.eventStore.event(withIdentifier: identifier) else {
            throw SyncError.calendarNotFound
        }
        try eventKit.eventStore.remove(event, span: .thisEvent, commit: true)
    }

    func archiveProjectsWithMissingCalendars(context: ModelContext) async throws {
        try await eventKit.requireCalendarAccess()
        let ids = Set(eventKit.eventStore.calendars(for: .event).map(\.calendarIdentifier))
        for project in try context.fetch(FetchDescriptor<Project>()) {
            guard let id = project.calendarIdentifier, !ids.contains(id) else { continue }
            project.status = .archived
            project.archivedAt = Date()
            project.updatedAt = Date()
            project.syncState = .failed
        }
        try context.save()
    }

    private func sync(block: WorkBlock) async {
        block.syncState = .syncing
        try? context.save()
        do {
            try await eventKit.requireCalendarAccess()
            guard block.endAt > block.startAt else { throw SyncError.invalidTimeRange }
            let calendar = try await targetCalendar(for: block)
            let event = block.eventIdentifier.flatMap { eventKit.eventStore.event(withIdentifier: $0) }
                ?? EKEvent(eventStore: eventKit.eventStore)
            event.title = block.title
            event.startDate = block.startAt
            event.endDate = block.endAt
            event.calendar = calendar
            event.notes = block.memo.isEmpty ? nil : block.memo
            try eventKit.eventStore.save(event, span: .thisEvent, commit: true)
            block.eventIdentifier = event.eventIdentifier
            block.calendarIdentifier = event.calendar.calendarIdentifier
            block.updatedAt = Date()
            block.syncState = .synced
            try context.save()
        } catch {
            block.syncState = .failed
            try? context.save()
        }
    }

    private func targetCalendar(for block: WorkBlock) async throws -> EKCalendar {
        if let projectId = block.projectId,
           let project = try context.fetch(FetchDescriptor<Project>()).first(where: { $0.id == projectId }) {
            if let identifier = project.calendarIdentifier,
               let calendar = eventKit.eventStore.calendar(withIdentifier: identifier) {
                return calendar
            }

            if let area = try context.fetch(FetchDescriptor<ProjectArea>()).first(where: { $0.id == project.areaId }),
               let identifier = area.calendarIdentifier,
               let calendar = eventKit.eventStore.calendar(withIdentifier: identifier) {
                project.calendarIdentifier = identifier
                project.calendarTitle = area.calendarTitle
                project.calendarColorHex = area.calendarColorHex
                try? context.save()
                return calendar
            }
        }

        if let identifier = block.calendarIdentifier,
           let calendar = eventKit.eventStore.calendar(withIdentifier: identifier) {
            return calendar
        }

        let blockCalendar = try await ensureBlockCalendar()
        guard let calendar = eventKit.eventStore.calendar(withIdentifier: blockCalendar.id) else {
            throw SyncError.calendarNotFound
        }
        return calendar
    }

    private func targetCalendar(projectId: UUID?, calendarIdentifier: String?) async throws -> EKCalendar {
        if let calendarIdentifier,
           let calendar = eventKit.eventStore.calendar(withIdentifier: calendarIdentifier) {
            return calendar
        }

        if let projectId,
           let project = try context.fetch(FetchDescriptor<Project>()).first(where: { $0.id == projectId }) {
            if let identifier = project.calendarIdentifier,
               let calendar = eventKit.eventStore.calendar(withIdentifier: identifier) {
                return calendar
            }

            if let area = try context.fetch(FetchDescriptor<ProjectArea>()).first(where: { $0.id == project.areaId }),
               let identifier = area.calendarIdentifier,
               let calendar = eventKit.eventStore.calendar(withIdentifier: identifier) {
                return calendar
            }
        }

        let blockCalendar = try await ensureBlockCalendar()
        guard let calendar = eventKit.eventStore.calendar(withIdentifier: blockCalendar.id) else {
            throw SyncError.calendarNotFound
        }
        return calendar
    }

    private func syncSettings() throws -> AppSyncSettings {
        if let existing = try context.fetch(FetchDescriptor<AppSyncSettings>()).first {
            return existing
        }
        let settings = AppSyncSettings()
        context.insert(settings)
        try context.save()
        return settings
    }

    private func preferredSource() -> EKSource? {
        eventKit.eventStore.sources.first { $0.sourceType == .calDAV && $0.title.localizedCaseInsensitiveContains("icloud") }
            ?? eventKit.eventStore.defaultCalendarForNewEvents?.source
            ?? eventKit.eventStore.sources.first { $0.sourceType == .local }
    }

    private func colorHex(_ calendar: EKCalendar) -> String? {
        guard let color = calendar.cgColor else { return nil }
        return UIColor(cgColor: color).hexRGB
    }
}

private extension UIColor {
    var hexRGB: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
