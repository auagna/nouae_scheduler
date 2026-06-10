import Combine
import EventKit

@MainActor
final class EventKitManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published private(set) var authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published private(set) var reminderAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)

    var hasFullAccess: Bool {
        if #available(iOS 17.0, *) { return authorizationStatus == .fullAccess }
        return authorizationStatus.rawValue == 3
    }

    var hasReminderFullAccess: Bool {
        if #available(iOS 17.0, *) { return reminderAuthorizationStatus == .fullAccess }
        return reminderAuthorizationStatus.rawValue == 3
    }

    func requireCalendarAccess() async throws {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if hasFullAccess { return }
        let granted: Bool
        if #available(iOS 17.0, *) { granted = try await eventStore.requestFullAccessToEvents() }
        else { granted = try await eventStore.requestAccess(to: .event) }
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard granted else { throw SyncError.permissionDenied }
    }

    func requireReminderAccess() async throws {
        reminderAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        if hasReminderFullAccess { return }
        let granted: Bool
        if #available(iOS 17.0, *) { granted = try await eventStore.requestFullAccessToReminders() }
        else { granted = try await eventStore.requestAccess(to: .reminder) }
        reminderAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard granted else { throw SyncError.reminderPermissionDenied }
    }
}
