import Combine
import EventKit
import Foundation
import SwiftData

@MainActor
final class EventKitManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published private(set) var hasFullAccess = false
    @Published private(set) var hasReminderFullAccess = false

    init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        if #available(iOS 17.0, *) {
            let eventStatus = EKEventStore.authorizationStatus(for: .event)
            hasFullAccess = eventStatus == .fullAccess || eventStatus == .writeOnly
            hasReminderFullAccess = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
        } else {
            hasFullAccess = EKEventStore.authorizationStatus(for: .event) == .authorized
            hasReminderFullAccess = EKEventStore.authorizationStatus(for: .reminder) == .authorized
        }
    }

    func requireCalendarAccess() async throws {
        refreshAuthorizationStatus()
        if hasFullAccess { return }
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = try await eventStore.requestFullAccessToEvents()
        } else {
            granted = try await eventStore.requestAccess(to: .event)
        }
        refreshAuthorizationStatus()
        guard granted || hasFullAccess else { throw SyncError.permissionDenied }
    }

    func requireReminderAccess() async throws {
        refreshAuthorizationStatus()
        if hasReminderFullAccess { return }
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = try await eventStore.requestFullAccessToReminders()
        } else {
            granted = try await eventStore.requestAccess(to: .reminder)
        }
        refreshAuthorizationStatus()
        guard granted || hasReminderFullAccess else { throw SyncError.reminderPermissionDenied }
    }
}

@MainActor
final class AppServices: ObservableObject {
    let eventKit: EventKitManager
    let calendarSync: CalendarSyncManager
    let reminderSync: ReminderSyncManager
    let moduleActionRouter: ModuleActionRouter

    init(context: ModelContext, stores: AppStores) {
        let eventKit = EventKitManager()
        self.eventKit = eventKit
        calendarSync = CalendarSyncManager(eventKit: eventKit, context: context)
        reminderSync = ReminderSyncManager(eventKit: eventKit, context: context, rawTaskStore: stores.rawTaskStore)
        moduleActionRouter = ModuleActionRouter(stores: stores)
    }
}
