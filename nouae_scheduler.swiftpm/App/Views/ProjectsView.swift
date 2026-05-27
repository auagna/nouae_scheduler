import SwiftUI

struct ProjectsView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @ObservedObject var projectStore: ProjectStore

    @State private var selectedCategory: ScheduleCategory?
    @State private var calendarSources: [CalendarSource] = []
    @State private var isShowingAddProject = false
    @State private var message: String?

    private var filteredProjects: [Project] {
        projectStore.projects(for: selectedCategory)
    }

    private var calendarTitleById: [String: String] {
        Dictionary(uniqueKeysWithValues: calendarSources.map { ($0.id, $0.title) })
    }

    var body: some View {
        List {
            Section {
                categoryFilter
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            if let message {
                Section {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }

            Section("프로젝트") {
                if filteredProjects.isEmpty {
                    Text("프로젝트가 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredProjects) { project in
                        NavigationLink {
                            ProjectDetailView(
                                project: project,
                                calendarTitle: calendarTitle(for: project),
                                projectStore: projectStore
                            )
                        } label: {
                            ProjectCard(
                                project: project,
                                summary: projectStore.summary(for: project),
                                calendarTitle: calendarTitle(for: project)
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddProject = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddProject) {
            NavigationStack {
                AddProjectView(
                    eventKitManager: eventKitManager,
                    projectStore: projectStore,
                    onSave: { Task { await loadCalendars() } }
                )
            }
        }
        .task {
            await loadCalendars()
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton(title: "전체", category: nil)
                ForEach(ScheduleCategory.allCases) { category in
                    filterButton(title: category.rawValue, category: category)
                }
            }
        }
    }

    private func filterButton(title: String, category: ScheduleCategory?) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected(category) ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ category: ScheduleCategory?) -> Bool {
        selectedCategory == category
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
