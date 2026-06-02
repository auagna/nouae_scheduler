import Combine
import EventKit

@MainActor
final class EventKitManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published private(set) var authorizationStatus = EKEventStore.authorizationStatus(for: .event)

    var hasFullAccess: Bool {
        if #available(iOS 17.0, *) { return authorizationStatus == .fullAccess }
        return authorizationStatus == .authorized
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
}
