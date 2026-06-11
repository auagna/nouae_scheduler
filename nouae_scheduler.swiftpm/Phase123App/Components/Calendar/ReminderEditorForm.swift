import SwiftUI

struct ReminderEditorDraft {
    var title = ""
    var notes = ""
    var urlString = ""
    var hasDate = true
    var hasTime = true
    var dueAt = Date()
    var isUrgent = false
    var repeatRule = "안 함"
    var listIdentifier: String?
    var projectId: UUID?
    var details = ""
}

struct ReminderEditorForm: View {
    @Binding var draft: ReminderEditorDraft
    let reminderLists: [ReminderListSource]
    let projects: [Project]

    var body: some View {
        Form {
            Section("미리 알림") {
                TextField("제목", text: $draft.title)
                TextField("메모", text: $draft.notes, axis: .vertical)
                    .lineLimit(2...5)
                TextField("URL", text: $draft.urlString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
            }

            Section("날짜 및 시간") {
                Toggle("날짜", isOn: $draft.hasDate)
                if draft.hasDate {
                    Toggle("시간", isOn: $draft.hasTime)
                    DatePicker(
                        "마감",
                        selection: $draft.dueAt,
                        displayedComponents: draft.hasTime ? [.date, .hourAndMinute] : [.date]
                    )
                }
                Toggle("긴급", isOn: $draft.isUrgent)
                Picker("반복", selection: $draft.repeatRule) {
                    Text("안 함").tag("안 함")
                    Text("매일").tag("매일")
                    Text("매주").tag("매주")
                    Text("매월").tag("매월")
                }
            }

            Section("목록") {
                Picker("Project", selection: $draft.projectId) {
                    Text("Project 없음").tag(nil as UUID?)
                    ForEach(projects) { project in
                        Text(project.title).tag(project.id as UUID?)
                    }
                }

                Picker("목록", selection: $draft.listIdentifier) {
                    Text("Project / BLOCK 기본값").tag(nil as String?)
                    ForEach(reminderLists) { list in
                        Text(list.title).tag(list.id as String?)
                    }
                }
            }

            Section("세부사항") {
                TextField("세부사항", text: $draft.details, axis: .vertical)
                    .lineLimit(2...4)
                Text("긴급은 Apple Reminders priority로 저장합니다. 반복 규칙은 MVP에서 메모 기준으로 보존합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
