import SwiftData
import SwiftUI

struct FoundationRootView: View {
    var body: some View {
        TabView {
            NavigationStack { FoundationDashboardView() }
                .tabItem { Label("Dashboard", systemImage: "chart.bar.doc.horizontal") }
            NavigationStack { DataFoundationView() }
                .tabItem { Label("Data", systemImage: "externaldrive") }
            NavigationStack { FoundationProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

struct FoundationDashboardView: View {
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @State private var todaySummary: DashboardTodaySummary?
    @State private var closingSummary: DashboardClosingSummary?
    @State private var message: String?

    var body: some View {
        List {
            Section("Today Summary") {
                LabeledContent("Projects", value: "\(projects.filter { !$0.isArchived }.count)")
                LabeledContent("RawTask Inbox", value: "\(tasks.filter { !$0.isConvertedToBlock }.count)")
                LabeledContent("WorkBlocks", value: "\(todaySummary?.totalBlocks ?? 0)")
                LabeledContent("Planned", value: "\(todaySummary?.plannedBlocks ?? 0)")
                LabeledContent("In Progress", value: "\(todaySummary?.inProgressBlocks ?? 0)")
            }

            Section("Closing Preview") {
                LabeledContent("Completed", value: "\(closingSummary?.completedBlocks ?? 0)")
                LabeledContent("Delayed", value: "\(closingSummary?.delayedBlocks ?? 0)")
                LabeledContent("Stopped", value: "\(closingSummary?.stoppedBlocks ?? 0)")
                LabeledContent("Completed Minutes", value: "\(closingSummary?.completedMinutes ?? 0)")
            }

            Section("Today WorkBlocks") {
                let todayBlocks = blocks.filter { Calendar.current.isDateInToday($0.startAt) }
                if todayBlocks.isEmpty {
                    ContentUnavailableView("No WorkBlocks", systemImage: "calendar.badge.plus")
                }
                ForEach(todayBlocks) { block in
                    WorkBlockFoundationRow(block: block)
                }
            }

            if let message {
                Section { Text(message).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Dashboard")
        .toolbar {
            Button { refresh() } label: { Image(systemName: "arrow.clockwise") }
        }
        .task { refresh() }
        .onChange(of: blocks.count) { _, _ in refresh() }
    }

    private func refresh() {
        do {
            todaySummary = try stores.dashboardStore.todaySummary()
            closingSummary = try stores.dashboardStore.closingSummary()
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
}

struct DataFoundationView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \WorkBlock.startAt, order: .reverse) private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query(sort: \ProjectMemoSection.order) private var memoSections: [ProjectMemoSection]
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]
    @State private var quickTaskTitle = ""
    @State private var message: String?

    var body: some View {
        List {
            Section("Local SwiftData") {
                LabeledContent("Projects", value: "\(projects.count)")
                LabeledContent("RawTasks", value: "\(tasks.count)")
                LabeledContent("WorkBlocks", value: "\(blocks.count)")
                LabeledContent("Logs", value: "\(logs.count)")
                LabeledContent("Memo Sections", value: "\(memoSections.count)")
                LabeledContent("Next Adjustments", value: "\(adjustments.count)")
            }

            Section("Quick RawTask") {
                TextField("Task title", text: $quickTaskTitle)
                Button { createQuickTask() } label: { Label("Add RawTask", systemImage: "plus") }
                    .disabled(quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Sample Data") {
                Button { seedSamples() } label: { Label("Create Sample Data", systemImage: "sparkles") }
                Text("샘플 데이터는 Project가 없을 때만 한 번 생성됩니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Projects") {
                if projects.isEmpty { Text("No projects").foregroundStyle(.secondary) }
                ForEach(projects) { project in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title).font(.headline)
                        Text("\(project.type.title) · \(project.status.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(project.calendarTitle ?? "Apple Calendar not linked")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("RawTask Inbox") {
                let inbox = tasks.filter { !$0.isConvertedToBlock }
                if inbox.isEmpty { Text("Inbox is empty").foregroundStyle(.secondary) }
                ForEach(inbox) { task in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                        Text(task.syncState.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let message {
                Section { Text(message).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Data Foundation")
    }

    private func createQuickTask() {
        do {
            _ = try stores.rawTaskStore.createRawTask(title: quickTaskTitle)
            quickTaskTitle = ""
            message = "RawTask saved locally."
        } catch {
            message = error.localizedDescription
        }
    }

    private func seedSamples() {
        do {
            try SampleDataSeeder.seedIfNeeded(modelContext: modelContext)
            message = "Sample data is ready."
        } catch {
            message = error.localizedDescription
        }
    }
}

struct WorkBlockFoundationRow: View {
    let block: WorkBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(block.title).font(.headline)
                Spacer()
                Text(block.executionState.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: block.progress)
        }
    }
}

struct FoundationProfileView: View {
    var body: some View {
        List {
            Section("Data Layer") {
                LabeledContent("Persistence", value: "SwiftData")
                LabeledContent("Calendar Link", value: "Project.calendarIdentifier")
                LabeledContent("Event Link", value: "WorkBlock.eventIdentifier")
                LabeledContent("Reminder Link", value: "RawTask.reminderIdentifier")
            }
            Section("Next Step") {
                Text("EventKit 실제 동기화는 다음 단계에서 Store 바깥 서비스로 연결합니다.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Profile")
    }
}
