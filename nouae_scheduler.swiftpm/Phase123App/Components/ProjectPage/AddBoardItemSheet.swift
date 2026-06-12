import SwiftUI

struct AddBoardItemSheet: View {
    let project: Project
    let onSave: (ProjectBoardItemType, String, String, String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var type: ProjectBoardItemType = .note
    @State private var title = ""
    @State private var content = ""
    @State private var url = ""
    @State private var colorHex = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Board Item", selection: $type) {
                        ForEach(ProjectBoardItemType.allCases) { type in
                            Label(type.title, systemImage: type.symbolName).tag(type)
                        }
                    }
                }

                Section("Content") {
                    TextField("Title", text: $title)
                    TextField("Content", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("URL", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    TextField("Color Hex optional", text: $colorHex)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Text("Project Page는 \(project.title)의 감각, 방향, reference, insight가 쌓이는 vision board입니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Board Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedColor = colorHex.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(type, title, content, url, trimmedColor.isEmpty ? nil : trimmedColor)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
