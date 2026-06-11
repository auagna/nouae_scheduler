import SwiftData
import SwiftUI

struct ProjectsNotesView: View {
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \ProjectNote.updatedAt, order: .reverse) private var notes: [ProjectNote]

    let areas: [ProjectArea]
    let projects: [Project]

    @State private var selectedAreaId: UUID?
    @State private var selectedProjectId: UUID?
    @State private var selectedNoteType: ProjectNoteType = .workJournal
    @State private var message: String?
    @State private var showingPromptExport = false

    var body: some View {
        AppScreenContainer(spacing: 16) {
            AppPageHeader(
                title: "Project Notes",
                subtitle: "Area와 Project를 오프라인 노트북처럼 넘겨보는 thinking space입니다."
            ) {
                Button {
                    showingPromptExport = true
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Vision Board Prompt")
            }

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            areaTabs
            projectTabs
            noteTypeTabs

            if let note = currentNote {
                ProjectNoteEditor(note: note)
            } else {
                AppPanel(title: selectedNoteType.title, subtitle: "아직 이 노트가 없습니다.") {
                    Button {
                        ensureNotesForCurrentProject()
                    } label: {
                        Label("노트 만들기", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task {
            prepareInitialSelection()
            ensureNotesForCurrentProject()
        }
        .onChange(of: selectedAreaId) { _, _ in
            selectedProjectId = projectsForSelectedArea.first?.id
            ensureNotesForCurrentProject()
        }
        .onChange(of: selectedProjectId) { _, _ in
            ensureNotesForCurrentProject()
        }
        .sheet(isPresented: $showingPromptExport) {
            PromptExportView(initialType: .projectVisionBoardReview, selectedProjectId: selectedProjectId)
        }
    }

    private var areaTabs: some View {
        AppPanel(title: "Area Notebook", subtitle: "삶의 영역을 큰 노트북처럼 선택합니다.") {
            if areas.isEmpty {
                Text("Area가 없습니다. List View에서 Area를 먼저 만들어 주세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(areas) { area in
                            Button {
                                selectedAreaId = area.id
                            } label: {
                                AreaNotebookTab(area: area, isSelected: selectedAreaId == area.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var projectTabs: some View {
        AppPanel(title: "Project Notes", subtitle: "선택한 Area 안의 작업세계를 넘겨봅니다.") {
            if projectsForSelectedArea.isEmpty {
                Text("이 Area에 Project가 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(projectsForSelectedArea) { project in
                            Button {
                                selectedProjectId = project.id
                            } label: {
                                projectNotebookCard(project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let project = selectedProject {
                    NavigationLink {
                        ProjectDashboardView(project: project)
                    } label: {
                        Label("Project Dashboard로 이동", systemImage: "rectangle.grid.2x2")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var noteTypeTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProjectNoteType.allCases) { type in
                    Button {
                        selectedNoteType = type
                    } label: {
                        ProjectNoteTab(type: type, isSelected: selectedNoteType == type)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func projectNotebookCard(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(calendarHex: project.calendarColorHex))
                    .frame(width: 9, height: 9)
                Text(project.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            StatusBadge(project.status.title, tone: selectedProjectId == project.id ? .blue : .neutral)
        }
        .frame(width: 180, alignment: .leading)
        .padding(12)
        .background(
            selectedProjectId == project.id ? Color.accentColor.opacity(0.12) : Color(uiColor: .tertiarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var projectsForSelectedArea: [Project] {
        projects
            .filter { $0.status != .archived && $0.areaId == selectedAreaId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var selectedProject: Project? {
        guard let selectedProjectId else { return nil }
        return projects.first { $0.id == selectedProjectId }
    }

    private var currentNote: ProjectNote? {
        notes.first {
            $0.areaId == selectedAreaId &&
            $0.projectId == selectedProjectId &&
            $0.noteType == selectedNoteType &&
            $0.archivedAt == nil
        }
    }

    private func prepareInitialSelection() {
        if selectedAreaId == nil {
            selectedAreaId = areas.first?.id
        }
        if selectedProjectId == nil {
            selectedProjectId = projectsForSelectedArea.first?.id
        }
    }

    private func ensureNotesForCurrentProject() {
        guard let project = selectedProject else { return }
        do {
            try stores.projectNoteStore.ensureDefaultNotes(
                areaId: selectedAreaId,
                projectId: project.id,
                projectTitle: project.title
            )
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
}
