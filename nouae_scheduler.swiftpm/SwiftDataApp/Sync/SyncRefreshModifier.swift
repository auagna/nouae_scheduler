import EventKit
import SwiftUI

struct SyncRefreshModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var services: AppServices

    func body(content: Content) -> some View {
        content
            .task { await refresh() }
            .onChange(of: scenePhase) {
                if scenePhase == .active { Task { await refresh() } }
            }
    }

    private func refresh() async {
        services.eventKitManager.refreshAuthorizationStatus()
        if services.eventKitManager.reminderAuthorizationStatus == .fullAccess {
            _ = try? await services.reminderSyncManager.importInboxReminders()
        }
        if services.eventKitManager.calendarAuthorizationStatus == .fullAccess {
            try? await services.calendarSyncManager.reconcileLinkedWorkBlocksFromApple()
            try? await services.calendarSyncManager.archiveProjectsWithMissingCalendars()
        }
    }
}
