import EventKit
import SwiftData
import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @State private var showingAddProject = false
    @State private var message: String?
    @State private var isCheckingCalendars = false

    var body: some View {
        NavigationStack {
            List {
                if let message {
                    Section { Text(message).font(.caption).foregroundStyle(.secondary) }
                }
                ForEach(ProjectStatus.allCases) { status in
                    let group = projects.filter { $0.status == status }
                    if !group.isEmpty {
                        Section(status.title) {
                            ForEach(group) { project in
                                ProjectCard(project: project)
                            }
                        }
                    }
                }
                if projects.isEmpty {
                    ContentUnavailableView(
                        "프로젝트 없음",
                        systemImage: "folder",
                        description: Text("새 프로젝트를 만들면 같은 이름의 Apple Calendar가 생성됩니다.")
                    )
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { detectDeletedCalendars() } label: {
                        if isCheckingCalendars { ProgressView() } else { Image(systemName: "arrow.triangle.2.circlepath") }
                    }
                    .disabled(isCheckingCalendars)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddProject = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
                    .environmentObject(stores)
                    .environmentObject(services)
            }
            .task {
                if services.eventKitManager.hasCalendarAccess {
                    detectDeletedCalendars()
                }
            }
        }
    }

    private func detectDeletedCalendars() {
        isCheckingCalendars = true
        Task {
            defer { isCheckingCalendars = false }
            do {
                try await stores.projectStore.archiveProjectsWithMissingCalendars(
                    calendarSyncManager: services.calendarSyncManager
                )
                message = "Apple Calendar 연결 상태를 확인했습니다."
            } catch {
                message = error.localizedDescription
            }
        }
    }
}

struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @State private var title = ""
    @State private var type: ProjectType = .personal
    @State private var status: ProjectStatus = .planning
    @State private var goal = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("프로젝트명", text: $title)
                    Picker("유형", selection: $type) {
                        ForEach(ProjectType.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("상태", selection: $status) {
                        ForEach(ProjectStatus.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("목표", text: $goal, axis: .vertical)
                }
                Section("Apple Calendar") {
                    Label("같은 이름의 Calendar를 자동 생성합니다.", systemImage: "calendar.badge.plus")
                    Text("Calendar 색상은 Apple Calendar에서 관리하며 nou ae에서는 읽기만 합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("새 프로젝트")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }.disabled(isCreating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { create() } label: {
                        if isCreating { ProgressView() } else { Text("생성") }
                    }
                    .disabled(isCreating || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func create() {
        isCreating = true
        errorMessage = nil
        Task {
            defer { isCreating = false }
            do {
                _ = try await stores.projectStore.createProjectWithCalendar(
                    title: title,
                    type: type,
                    status: status,
                    goal: goal,
                    calendarSyncManager: services.calendarSyncManager
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
