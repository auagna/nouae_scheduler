import SwiftUI

struct AddReminderView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var dueDate = Date()
    @State private var category: ScheduleCategory = .work
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("할 일") {
                TextField("제목", text: $title)
                DatePicker("마감일", selection: $dueDate)
            }

            Section("카테고리") {
                CategoryPicker(selectedCategory: $category)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("할 일 추가")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "저장 중" : "저장") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await eventKitManager.createReminder(title: title, dueDate: dueDate, category: category)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
