import SwiftData
import SwiftUI

struct ProjectNoteEditor: View {
    @Environment(\.modelContext) private var context
    @Bindable var note: ProjectNote

    var body: some View {
        AppPanel(title: note.noteType.title, subtitle: subtitle) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("노트 제목", text: $note.title)
                    .font(.headline)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: note.title) { _, _ in saveSoon() }

                if note.noteType == .sketch {
                    sketchPlaceholder
                }

                TextEditor(text: $note.content)
                    .frame(minHeight: 220)
                    .padding(10)
                    .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppUI.separatorColor, lineWidth: 1)
                    }
                    .onChange(of: note.content) { _, _ in saveSoon() }
            }
        }
    }

    private var subtitle: String {
        "Updated \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private var sketchPlaceholder: some View {
        HStack(spacing: 10) {
            Image(systemName: "pencil.and.outline")
                .foregroundStyle(.secondary)
            Text("스케치 데이터 저장 구조가 준비되어 있습니다. 고급 PencilKit 편집은 Calendar Drawing과 공통 컴포넌트로 확장합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func saveSoon() {
        note.updatedAt = Date()
        try? context.save()
    }
}
