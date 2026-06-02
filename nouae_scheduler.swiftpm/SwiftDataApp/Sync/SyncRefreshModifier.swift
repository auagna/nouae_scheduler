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
        _ = try? await services.reminderSyncManager.importInboxReminders()
        try? await services.calendarSyncManager.archiveProjectsWithMissingCalendars()
    }
}
