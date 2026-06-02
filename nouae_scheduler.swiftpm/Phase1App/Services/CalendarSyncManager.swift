import Combine
import EventKit
import Foundation
import SwiftData
import UIKit

struct CalendarSource: Identifiable, Hashable {
    let id: String
    let title: String
    let colorHex: String?
}

@MainActor
final class CalendarSyncManager: ObservableObject {
    private let eventKitManager: EventKitManager

    @Published private(set) var lastErrorMessage: String?

    init(eventKitManager: EventKitManager) {
        self.eventKitManager = eventKitManager
    }

    func fetchCalendars() async throws -> [CalendarSource] {
        try await eventKitManager.requireCalendarAccess()
        return eventKitManager.eventStore.calendars(for: .event)
            .map(makeSource)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func createCalendar(title: String) async throws -> CalendarSource {
        try await eventKitManager.requireCalendarAccess()
        guard let source = sourceForNewCalendar() else {
            throw SyncError.sourceNotFound
        }

        let calendar = EKCalendar(for: .event, eventStore: eventKitManager.eventStore)
        calendar.title = title
        calendar.source = source

        do {
            try eventKitManager.eventStore.saveCalendar(calendar, commit: true)
            lastErrorMessage = nil
            return makeSource(calendar)
        } catch {
            lastErrorMessage = error.localizedDescription
            throw SyncError.calendarCreationFailed
        }
    }

    func createCalendarForProject(project: Project) async throws -> CalendarSource {
        try await createCalendar(title: project.title)
    }

    func detectDeletedCalendars(projects: [Project]) async throws -> [Project] {
        let calendarIds = Set(try await fetchCalendars().map(\.id))
        return projects.filter { project in
            guard let identifier = project.calendarIdentifier else { return false }
            return !calendarIds.contains(identifier)
        }
    }

    func archiveProjectsWithMissingCalendars(context: ModelContext) async throws {
        let projects = try context.fetch(FetchDescriptor<Project>())
        for project in try await detectDeletedCalendars(projects: projects) {
            project.status = .archived
            project.archivedAt = Date()
            project.updatedAt = Date()
            project.syncState = .failed
        }
        try context.save()
    }

    func colorHex(from calendar: EKCalendar) -> String? {
        UIColor(cgColor: calendar.cgColor).hexRGB
    }

    private func makeSource(_ calendar: EKCalendar) -> CalendarSource {
        CalendarSource(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            colorHex: colorHex(from: calendar)
        )
    }

    private func sourceForNewCalendar() -> EKSource? {
        let sources = eventKitManager.eventStore.sources
        if let iCloud = sources.first(where: {
            $0.sourceType == .calDAV && $0.title.localizedCaseInsensitiveContains("icloud")
        }) {
            return iCloud
        }
        return eventKitManager.eventStore.defaultCalendarForNewEvents?.source
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
