import SwiftUI

struct QuickInputPanel: View {
    @ObservedObject var store: TimeBlockStore
    @ObservedObject var eventKitManager: EventKitManager
    @ObservedObject var projectStore: ProjectStore

    @State private var title = ""
    @State private var category: ScheduleCategory = .work
    @State private var selectedProjectId: UUID?
    @State private var startAt = Date()
    @State private var endAt = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    @State private var isShowingReminderSheet = false

    private var categoryProjects: [Project] {
        projectStore.projects(for: category)
    }

    private var selectedProject: Project? {
        projectStore.project(id: selectedProjectId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                TextField("빠른 일정 입력", text: $title)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addTimeBlock()
                } label: {
                    Image(systemName: "calendar.badge.plus")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    isShowingReminderSheet = true
                } label: {
                    Image(systemName: "checklist")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.bordered)
            }

            CategoryPicker(selectedCategory: $category)
                .onChange(of: category) { _ in
                    selectedProjectId = nil
                }

            ProjectPicker(projects: categoryProjects, selectedProjectId: $selectedProjectId)

            HStack {
                DatePicker("시작", selection: $startAt, displayedComponents: [.hourAndMinute])
                DatePicker("종료", selection: $endAt, displayedComponents: [.hourAndMinute])
            }
            .font(.caption)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .sheet(isPresented: $isShowingReminderSheet) {
            NavigationStack {
                AddReminderView(eventKitManager: eventKitManager)
            }
        }
    }

    private func addTimeBlock() {
        store.createBlock(title: title, category: category, project: selectedProject, startAt: startAt, endAt: endAt)
        title = ""
        let nextStart = Calendar.current.date(byAdding: .minute, value: 30, to: startAt) ?? Date()
        startAt = nextStart
        endAt = Calendar.current.date(byAdding: .minute, value: 30, to: nextStart) ?? nextStart
    }
}
