import Combine
import EventKit
import Foundation
import UIKit

@MainActor
final class EventKitManager: ObservableObject {
    let eventStore = EKEventStore()

    @Published private(set) var calendarAuthorizationStatus: EKAuthorizationStatus
    @Published private(set) var reminderAuthorizationStatus: EKAuthorizationStatus

    init() {
        calendarAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
        reminderAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    }

    func refreshAuthorizationStatus() {
        calendarAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
        reminderAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    }

    func requestCalendarAccess() async throws -> Bool {
        let granted = try await eventStore.requestFullAccessToEvents()
        refreshAuthorizationStatus()
        return granted
    }

    func requestReminderAccess() async throws -> Bool {
        let granted = try await eventStore.requestFullAccessToReminders()
        refreshAuthorizationStatus()
        return granted
    }

    func requireCalendarAccess() async throws {
        refreshAuthorizationStatus()
        guard calendarAuthorizationStatus == .fullAccess else {
            guard try await requestCalendarAccess() else {
                throw SyncError.calendarAccessDenied
            }
            return
        }
    }

    func requireReminderAccess() async throws {
        refreshAuthorizationStatus()
        guard reminderAuthorizationStatus == .fullAccess else {
            guard try await requestReminderAccess() else {
                throw SyncError.reminderAccessDenied
            }
            return
        }
    }

    func availableEventCalendars() -> [EKCalendar] {
        eventStore.calendars(for: .event).sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    func availableReminderCalendars() -> [EKCalendar] {
        eventStore.calendars(for: .reminder).sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    func calendar(identifier: String) -> EKCalendar? {
        eventStore.calendar(withIdentifier: identifier)
    }

    func sourceForNewCalendar() -> EKSource? {
        if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
            return defaultSource
        }
        if let iCloud = eventStore.sources.first(where: {
            $0.sourceType == .calDAV && $0.title.localizedCaseInsensitiveContains("icloud")
        }) {
            return iCloud
        }
        return eventStore.sources.first(where: { $0.sourceType == .local })
    }

    func calendarColorHex(_ calendar: EKCalendar) -> String? {
        UIColor(cgColor: calendar.cgColor).hexRGB
    }
}

private extension UIColor {
    var hexRGB: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
