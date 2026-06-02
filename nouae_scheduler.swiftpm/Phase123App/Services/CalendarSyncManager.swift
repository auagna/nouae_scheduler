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

    func createCalendar(title: String) async throws -> CalendarSource {
        try await eventKit.requireCalendarAccess()
        guard let source = preferredSource() else { throw SyncError.sourceNotFound }
        let calendar = EKCalendar(for: .event, eventStore: eventKit.eventStore)
        calendar.title = title
        calendar.source = source
        do { try eventKit.eventStore.saveCalendar(calendar, commit: true) }
        catch { throw SyncError.calendarCreationFailed }
        return CalendarSource(id: calendar.calendarIdentifier, title: calendar.title, colorHex: colorHex(calendar))
    }

    func scheduleSync(block: WorkBlock) {
        debounceTasks[block.id]?.cancel()
        block.syncState = .pending
        try? context.save()
        debounceTasks[block.id] = Task { [weak self, weak block] in
            do { try await Task.sleep(nanoseconds: 3_000_000_000) }
            catch { return }
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
            guard let calendarIdentifier = block.calendarIdentifier,
                  let calendar = eventKit.eventStore.calendar(withIdentifier: calendarIdentifier) else {
                throw SyncError.calendarNotFound
            }
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
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
