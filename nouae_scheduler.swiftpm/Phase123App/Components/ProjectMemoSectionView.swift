import SwiftData
import SwiftUI

struct ProjectMemoSectionView: View {
    let project: Project
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \ProjectMemoSection.order) private var sections: [ProjectMemoSection]
    @State private var title = ""
    @State private var content = ""

    var body: some View {
        Section("메모") {
            ForEach(sections.filter { $0.projectId == project.id }) { section in VStack(alignment: .leading, spacing: 3) { Text(section.title).font(.subheadline.weight(.semibold)); Text(section.content.isEmpty ? "내용 없음" : section.content).font(.caption).foregroundStyle(.secondary) } }
            TextField("새 섹션 제목", text: $title)
            TextField("내용", text: $content)
            Button("메모 섹션 추가") { add() }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    private func add() { try? stores.projectStore.addMemoSection(projectId: project.id, title: title, content: content); title = ""; content = "" }
}
