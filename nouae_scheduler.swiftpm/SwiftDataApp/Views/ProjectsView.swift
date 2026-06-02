import SwiftData
import SwiftUI

struct ProjectsView: View {
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @State private var showingAddProject = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(ProjectStatus.allCases) { status in
                    let group = projects.filter { $0.status == status }
                    if !group.isEmpty {
                        Section(status.title) {
                            ForEach(group) { project in
                                NavigationLink { ProjectDashboardView(project: project) } label: { ProjectCard(project: project) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar { Button { showingAddProject = true } label: { Image(systemName: "plus") } }
            .sheet(isPresented: $showingAddProject) { AddProjectView() }
        }
    }
}

struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @State private var title = ""
    @State private var goal = ""
    @State private var type: ProjectType = .personal
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("프로젝트명", text: $title)
                Picker("성격", selection: $type) { ForEach(ProjectType.allCases) { Text($0.title).tag($0) } }
                TextField("목표", text: $goal, axis: .vertical)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("새 프로젝트")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("생성") { create() }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }

    private func create() {
        Task {
            do {
                let project = try stores.projectStore.createProject(title: title, type: type, goal: goal)
                try await services.calendarSyncManager.createCalendarForProject(project)
                dismiss()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}

struct ProjectDashboardView: View {
    let project: Project
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \WorkBlock.startAt, order: .reverse) private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query(sort: \ProjectMemoSection.order) private var memoSections: [ProjectMemoSection]
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]

    private var projectBlocks: [WorkBlock] { blocks.filter { $0.projectId == project.id } }
    private var progress: Double { projectBlocks.isEmpty ? 0 : projectBlocks.map(\.progress).reduce(0, +) / Double(projectBlocks.count) }

    var body: some View {
        List {
            Section("Project Summary") {
                ProjectCard(project: project)
                Picker("상태", selection: statusBinding) { ForEach(ProjectStatus.allCases) { Text($0.title).tag($0) } }
                ProgressView(value: progress)
                Text(project.goal.isEmpty ? "목표를 입력하세요." : project.goal)
            }
            Section("Apple Calendar") { Text(project.calendarTitle ?? "연결된 캘린더 없음"); Text(project.calendarIdentifier == nil ? "동기화 연결 필요" : "동기화 연결됨").foregroundStyle(.secondary) }
            Section("Inbox") { ForEach(tasks.filter { $0.projectId == project.id && !$0.isConvertedToBlock }) { Text($0.title) } }
            Section("오늘 작업") { ForEach(projectBlocks.filter { Calendar.current.isDateInToday($0.startAt) }) { WorkBlockSummaryRow(block: $0) } }
            Section("메모") { ForEach(memoSections.filter { $0.projectId == project.id }) { section in VStack(alignment: .leading) { Text(section.title).font(.headline); Text(section.content.isEmpty ? "내용 없음" : section.content).foregroundStyle(.secondary) } } }
            Section("다음 조정") { ForEach(adjustments.filter { $0.projectId == project.id && $0.isActive }.prefix(3)) { Text($0.content) } }
            Section("최근 로그") { ForEach(logs.filter { $0.projectId == project.id }.prefix(3)) { Text($0.content.isEmpty ? "회고 메모 없음" : $0.content) } }
        }
        .navigationTitle(project.title)
    }

    private var statusBinding: Binding<ProjectStatus> {
        Binding(get: { project.status }, set: { try? stores.projectStore.updateProject(project, status: $0) })
    }
}
