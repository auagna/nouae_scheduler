import SwiftData
import SwiftUI

struct ProjectsPlaceholderView: View {
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]

    var body: some View {
        NavigationStack {
            List {
                if projects.isEmpty {
                    ContentUnavailableView("Projects", systemImage: "folder", description: Text("프로젝트 생성 UI는 다음 Phase에서 연결합니다."))
                } else {
                    ForEach(projects) { project in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.title).font(.headline)
                            Text(project.type.title + " · " + project.status.title).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Projects")
        }
    }
}
