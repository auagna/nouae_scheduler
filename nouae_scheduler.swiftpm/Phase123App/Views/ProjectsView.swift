import SwiftData
import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \ProjectArea.updatedAt, order: .reverse) private var areas: [ProjectArea]
    @Query private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @State private var showingAdd = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                if let message {
                    Section {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Areas") {
                    if areas.isEmpty {
                        Text("Area가 없습니다. 새 Project 생성 화면에서 Area를 먼저 만들 수 있습니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(areas) { area in
                        HStack {
                            Circle()
                                .fill(Color(calendarHex: area.calendarColorHex))
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(area.title)
                                Text(area.calendarTitle ?? "Calendar 미연결")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(area.syncState.title)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(ProjectStatus.allCases) { status in
                    let items = projects.filter { $0.status == status }
                    if !items.isEmpty {
                        Section(status.title) {
                            ForEach(items) { project in
                                NavigationLink {
                                    ProjectDashboardView(project: project)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ProjectCard(
                                            project: project,
                                            blocks: blocks.filter { $0.projectId == project.id },
                                            logs: logs.filter { $0.projectId == project.id }
                                        )
                                        Text(areaTitle(for: project))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { refresh() } label: { Image(systemName: "arrow.triangle.2.circlepath") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) { AddProjectView() }
            .task {
                if services.eventKit.hasFullAccess { refresh() }
            }
        }
    }

    private func areaTitle(for project: Project) -> String {
        guard let areaId = project.areaId,
              let area = areas.first(where: { $0.id == areaId }) else {
            return "Area: Unassigned"
        }
        return "Area: \(area.title)"
    }

    private func refresh() {
        Task {
            do {
                try await stores.projectStore.archiveProjectsWithMissingCalendars(calendarSyncManager: services.calendarSync)
                message = "Calendar 연결 상태를 확인했습니다."
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
    @Query(sort: \ProjectArea.updatedAt, order: .reverse) private var areas: [ProjectArea]

    @State private var title = ""
    @State private var type: ProjectType = .personal
    @State private var status: ProjectStatus = .planning
    @State private var goal = ""
    @State private var selectedAreaId: UUID?
    @State private var newAreaTitle = ""
    @State private var isCreating = false
    @State private var isCreatingArea = false
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

                Section("Area") {
                    Picker("Area", selection: $selectedAreaId) {
                        Text("Unassigned").tag(nil as UUID?)
                        ForEach(areas) { area in
                            Text(area.title).tag(area.id as UUID?)
                        }
                    }
                    HStack {
                        TextField("새 Area 이름", text: $newAreaTitle)
                        Button("추가") { createArea() }
                            .disabled(isCreatingArea || newAreaTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Text("Area를 만들면 같은 이름의 Apple Calendar와 Apple Reminder List를 함께 생성합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("새 프로젝트")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
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

    private func createArea() {
        isCreatingArea = true
        Task {
            defer { isCreatingArea = false }
            do {
                let area = try await stores.projectAreaStore.createArea(
                    title: newAreaTitle,
                    calendarSyncManager: services.calendarSync,
                    reminderSyncManager: services.reminderSync
                )
                selectedAreaId = area.id
                newAreaTitle = ""
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func create() {
        isCreating = true
        defer { isCreating = false }
        do {
            let area = selectedAreaId.flatMap { id in areas.first { $0.id == id } }
            _ = try stores.projectStore.createProjectInArea(title: title, type: type, status: status, goal: goal, area: area)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
