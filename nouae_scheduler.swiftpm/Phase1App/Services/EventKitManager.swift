import Combine
import EventKit
import Foundation

@MainActor
final class EventKitManager: ObservableObject {
    let eventStore: EKEventStore

    @Published private(set) var calendarAuthorizationStatus: EKAuthorizationStatus

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
        calendarAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func refreshAuthorizationStatus() {
        calendarAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestCalendarAccess() async throws -> Bool {
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = try await eventStore.requestFullAccessToEvents()
        } else {
            granted = try await eventStore.requestAccess(to: .event)
        }
        refreshAuthorizationStatus()
        return granted
    }

    func requireCalendarAccess() async throws {
        refreshAuthorizationStatus()
        if hasCalendarAccess { return }
        guard try await requestCalendarAccess() else {
            throw SyncError.permissionDenied
        }
    }

    var hasCalendarAccess: Bool {
        if #available(iOS 17.0, *) {
            return calendarAuthorizationStatus == .fullAccess
        }
        return calendarAuthorizationStatus == .authorized
    }
}
