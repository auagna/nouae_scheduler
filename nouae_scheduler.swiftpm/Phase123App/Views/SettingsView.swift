import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: AppServices

    @Query(sort: \AppSyncSettings.updatedAt, order: .reverse) private var syncSettings: [AppSyncSettings]
    @Query(sort: \ProjectArea.updatedAt, order: .reverse) private var areas: [ProjectArea]
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \WorkBlock.updatedAt, order: .reverse) private var blocks: [WorkBlock]

    @State private var isWorking = false
    @State private var message: String?
    @State private var showingSampleRemoval = false

    var body: some View {
        NavigationStack {
            AppScreenContainer(spacing: 18) {
                AppPageHeader(title: "Settings", subtitle: "Permission, BLOCK, sync recovery, and data controls") {
                    Button("Done") { dismiss() }
                        .buttonStyle(.bordered)
                }

                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                PermissionStatusCard(
                    title: "Calendar Permission",
                    explanation: "WorkBlock과 Area Calendar 동기화에 필요합니다.",
                    isGranted: services.eventKit.hasFullAccess,
                    systemImage: "calendar",
                    onRequest: { Task { await requestCalendarPermission() } },
                    onOpenSettings: openSystemSettings
                )

                PermissionStatusCard(
                    title: "Reminder Permission",
                    explanation: "RawTask Inbox와 Apple Reminders 연결에 필요합니다.",
                    isGranted: services.eventKit.hasReminderFullAccess,
                    systemImage: "checklist",
                    onRequest: { Task { await requestReminderPermission() } },
                    onOpenSettings: openSystemSettings
                )

                BlockSyncStatusCard(
                    calendarIdentifier: settings?.blockCalendarIdentifier,
                    reminderListIdentifier: settings?.blockReminderListIdentifier,
                    isWorking: isWorking,
                    onEnsure: { Task { await ensureBlockStores() } }
                )

                AreaSyncStatusList(areas: areas)

                PendingSyncList(blocks: pendingBlocks, tasks: pendingTasks) {
                    Task { await retryAllPendingSync() }
                }

                FailedSyncList(blocks: failedBlocks, tasks: failedTasks, projects: failedProjects) {
                    Task { await retryFailedSync() }
                }

                PlanSettingsSection()

                DataSettingsSection(
                    onExport: { message = "Export는 MVP 안정화 이후 파일 생성 흐름으로 다시 연결합니다." },
                    onRemoveSamples: { showingSampleRemoval = true }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("샘플 데이터를 제거할까요?", isPresented: $showingSampleRemoval, titleVisibility: .visible) {
                Button("샘플 데이터 제거", role: .destructive) {
                    removeSampleData()
                }
                Button("취소", role: .cancel) {}
            }
        }
    }

    private var settings: AppSyncSettings? { syncSettings.first }
    private var pendingBlocks: [WorkBlock] { blocks.filter { $0.syncState == .pending || $0.syncState == .syncing } }
    private var pendingTasks: [RawTask] { tasks.filter { $0.syncState == .pending || $0.syncState == .syncing } }
    private var failedBlocks: [WorkBlock] { blocks.filter { $0.syncState == .failed } }
    private var failedTasks: [RawTask] { tasks.filter { $0.syncState == .failed } }
    private var failedProjects: [Project] { projects.filter { $0.syncState == .failed } }

    private func requestCalendarPermission() async {
        await run {
            try await services.eventKit.requireCalendarAccess()
            message = "Calendar 권한을 확인했습니다."
        }
    }

    private func requestReminderPermission() async {
        await run {
            try await services.eventKit.requireReminderAccess()
            message = "Reminder 권한을 확인했습니다."
        }
    }

    private func ensureBlockStores() async {
        await run {
            _ = try await services.calendarSync.ensureBlockCalendar()
            _ = try await services.reminderSync.ensureBlockReminderList()
            message = "BLOCK Calendar와 Reminder List를 확인했습니다."
        }
    }

    private func retryAllPendingSync() async {
        await run {
            for block in pendingBlocks {
                services.calendarSync.scheduleSync(block: block)
            }
            for task in pendingTasks {
                try? await services.reminderSync.exportRawTask(task)
            }
            message = "Pending sync 재시도를 시작했습니다."
        }
    }

    private func retryFailedSync() async {
        await run {
            for block in failedBlocks {
                services.calendarSync.scheduleSync(block: block)
            }
            for task in failedTasks {
                try? await services.reminderSync.exportRawTask(task)
            }
            message = "Failed sync 재시도를 시작했습니다."
        }
    }

    private func removeSampleData() {
        do {
            try SampleDataSeeder.removeSampleData(context: context)
            message = "샘플 데이터를 제거했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func run(_ operation: @escaping () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await operation()
        } catch {
            message = error.localizedDescription
        }
    }
}