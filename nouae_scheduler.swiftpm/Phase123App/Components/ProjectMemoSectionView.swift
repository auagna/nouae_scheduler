import SwiftData
import SwiftUI

struct ProjectMemoSectionView: View {
    let project: Project
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \ProjectMemoSection.order) private var sections: [ProjectMemoSection]
    @State private var title = ""
    @State private var content = ""

    var body: some View {
        Section("Project Page") {
            ForEach(sections.filter { $0.projectId == project.id }) { section in
                ProjectMemoSectionEditor(section: section)
            }
            TextField("새 섹션 제목", text: $title)
            TextField("내용", text: $content, axis: .vertical)
                .lineLimit(2...4)
            Button("섹션 추가") { add() }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func add() {
        try? stores.projectStore.addMemoSection(projectId: project.id, title: title, content: content)
        title = ""
        content = ""
    }
}

private struct ProjectMemoSectionEditor: View {
    let section: ProjectMemoSection
    @EnvironmentObject private var stores: AppStores
    @State private var title: String
    @State private var content: String
    @State private var isEditing = false

    init(section: ProjectMemoSection) {
        self.section = section
        _title = State(initialValue: section.title)
        _content = State(initialValue: section.content)
    }

    var body: some View {
        DisclosureGroup {
            if isEditing {
                TextField("제목", text: $title)
                TextField("내용", text: $content, axis: .vertical)
                    .lineLimit(3...8)
                Button("저장") { save() }
            } else {
                Text(section.content.isEmpty ? "내용 없음" : section.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("수정") { isEditing = true }
            }
        } label: {
            Text(section.title)
                .font(.subheadline.weight(.semibold))
        }
    }

    private func save() {
        try? stores.projectStore.updateMemoSection(section: section, title: title, content: content)
        isEditing = false
    }
}
