import SwiftUI

struct ProjectsView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @ObservedObject var projectStore: ProjectStore
    @ObservedObject var calendarSelectionStore: CalendarSelectionStore

    @State private var selectedCategory: ScheduleCategory?
    @State private var selectedStatus: ProjectStatus?
    @State private var calendarSources: [CalendarSource] = []
    @State private var isShowingAddProject = false
    @State private var message: String?

    private var filteredProjects: [Project] {
        projectStore.projects(for: selectedCategory, status: selectedStatus)
    }

    private var calendarTitleById: [String: String] {
        Dictionary(uniqueKeysWithValues: calendarSources.map { ($0.id, $0.title) })
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    filterRow(title: "상태", allTitle: "전체", items: ProjectStatus.allCases.filter { $0 != .archived }, selected: $selectedStatus)
                    categoryFilter
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            if let message {
                Section { Text(message).foregroundStyle(.secondary) }
            }

            Section("프로젝트") {
                if filteredProjects.isEmpty {
                    Text("프로젝트가 없습니다.").foregroundStyle(.secondary)
                } else {
                    ForEach(filteredProjects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project, calendarTitle: calendarTitle(for: project), projectStore: projectStore)
                        } label: {
                            ProjectCard(project: project, summary: projectStore.summary(for: project), calendarTitle: calendarTitle(for: project))
                        }
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingAddProject = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isShowingAddProject) {
            NavigationStack {
                AddProjectView(
                    eventKitManager: eventKitManager,
                    projectStore: projectStore,
                    calendarSelectionStore: calendarSelectionStore,
                    calendarSources: calendarSources,
                    onSave: { Task { await loadCalendars() } }
                )
            }
        }
        .task { await loadCalendars() }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton(title: "전체", isSelected: selectedCategory == nil) { selectedCategory = nil }
                ForEach(ScheduleCategory.allCases) { category in
                    filterButton(title: category.rawValue, isSelected: selectedCategory == category) { selectedCategory = category }
                }
            }
        }
    }

    private func filterRow(title: String, allTitle: String, items: [ProjectStatus], selected: Binding<ProjectStatus?>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterButton(title: allTitle, isSelected: selected.wrappedValue == nil) { selected.wrappedValue = nil }
                    ForEach(items) { status in
                        filterButton(title: status.rawValue, isSelected: selected.wrappedValue == status) { selected.wrappedValue = status }
                    }
                }
            }
        }
    }

    private func filterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func calendarTitle(for project: Project) -> String? {
        guard let calendarIdentifier = project.calendarIdentifier else { return nil }
        return calendarTitleById[calendarIdentifier]
    }

    private func loadCalendars() async {
        do {
            calendarSources = try await eventKitManager.fetchCalendars()
            message = nil
        } catch {
            calendarSources = []
            message = "캘린더 목록을 불러오지 못했습니다. 프로젝트는 계속 사용할 수 있습니다."
        }
    }
}
