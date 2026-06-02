import SwiftData
import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @State private var showingAdd = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                if let message { Section { Text(message).font(.caption).foregroundStyle(.secondary) } }
                ForEach(ProjectStatus.allCases) { status in
                    let items = projects.filter { $0.status == status }
                    if !items.isEmpty { Section(status.title) { ForEach(items) { project in NavigationLink { ProjectDashboardView(project: project) } label: { ProjectCard(project: project, blocks: blocks.filter { $0.projectId == project.id }, logs: logs.filter { $0.projectId == project.id }) } } } }
                }
            }
            .navigationTitle("Projects")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { refresh() } label: { Image(systemName: "arrow.triangle.2.circlepath") } }; ToolbarItem(placement: .topBarTrailing) { Button { showingAdd = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $showingAdd) { AddProjectView() }
            .task { if services.eventKit.hasFullAccess { refresh() } }
        }
    }
    private func refresh() { Task { do { try await stores.projectStore.archiveProjectsWithMissingCalendars(calendarSyncManager: services.calendarSync); message = "Calendar 연결 상태를 확인했습니다." } catch { message = error.localizedDescription } } }
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
        NavigationStack { Form { TextField("프로젝트명", text: $title); Picker("유형", selection: $type) { ForEach(ProjectType.allCases) { Text($0.title).tag($0) } }; Picker("상태", selection: $status) { ForEach(ProjectStatus.allCases) { Text($0.title).tag($0) } }; TextField("목표", text: $goal, axis: .vertical); if let errorMessage { Text(errorMessage).foregroundStyle(.red) } }.navigationTitle("새 프로젝트").toolbar { ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button { create() } label: { if isCreating { ProgressView() } else { Text("생성") } }.disabled(isCreating || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) } } }
    }
    private func create() { isCreating = true; Task { defer { isCreating = false }; do { _ = try await stores.projectStore.createProject(title: title, type: type, status: status, goal: goal, calendarSyncManager: services.calendarSync); dismiss() } catch { errorMessage = error.localizedDescription } } }
}
