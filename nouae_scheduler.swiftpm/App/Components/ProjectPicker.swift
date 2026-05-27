import SwiftUI

struct ProjectPicker: View {
    let projects: [Project]
    @Binding var selectedProjectId: UUID?

    var body: some View {
        Picker("프로젝트", selection: $selectedProjectId) {
            Text("프로젝트 없음").tag(UUID?.none)
            ForEach(projects) { project in
                Text(project.title).tag(Optional(project.id))
            }
        }
        .pickerStyle(.menu)
    }
}
