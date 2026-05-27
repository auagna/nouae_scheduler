import SwiftUI

struct ProjectPageEditor: View {
    let project: Project
    @ObservedObject var projectStore: ProjectStore

    @State private var newTitle = ""
    @State private var newContent = ""

    var body: some View {
        List {
            Section("새 섹션") {
                TextField("제목", text: $newTitle)
                TextField("내용", text: $newContent, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                Button("섹션 추가") {
                    projectStore.addPageSection(project: project, title: newTitle, content: newContent)
                    newTitle = ""
                    newContent = ""
                }
            }

            Section("Project Page") {
                ForEach(projectStore.pageSections(for: project)) { section in
                    SectionEditorRow(section: section, projectStore: projectStore)
                }
            }
        }
        .navigationTitle("Project Page")
    }
}

private struct SectionEditorRow: View {
    let section: ProjectPageSection
    @ObservedObject var projectStore: ProjectStore

    @State private var title: String
    @State private var content: String

    init(section: ProjectPageSection, projectStore: ProjectStore) {
        self.section = section
        self.projectStore = projectStore
        _title = State(initialValue: section.title)
        _content = State(initialValue: section.content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("제목", text: $title)
                .font(.headline)
            TextField("내용", text: $content, axis: .vertical)
                .lineLimit(4, reservesSpace: true)
            HStack {
                if section.isGenerated {
                    Text("Generated")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { projectStore.moveSection(section, direction: -1) } label: { Image(systemName: "arrow.up") }
                Button { projectStore.moveSection(section, direction: 1) } label: { Image(systemName: "arrow.down") }
                Button("저장") {
                    projectStore.updatePageSection(section, title: title, content: content)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
