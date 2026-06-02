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
    init(eventKit: EventKitManager) { self.eventKit = eventKit }

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

    private func preferredSource() -> EKSource? {
        eventKit.eventStore.sources.first { $0.sourceType == .calDAV && $0.title.localizedCaseInsensitiveContains("icloud") }
            ?? eventKit.eventStore.defaultCalendarForNewEvents?.source
            ?? eventKit.eventStore.sources.first { $0.sourceType == .local }
    }
    private func colorHex(_ calendar: EKCalendar) -> String? { guard let color = calendar.cgColor else { return nil }; return UIColor(cgColor: color).hexRGB }
}

private extension UIColor {
    var hexRGB: String? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
