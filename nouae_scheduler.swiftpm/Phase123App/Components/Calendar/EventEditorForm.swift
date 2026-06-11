import SwiftUI

struct EventEditorDraft {
    var title = ""
    var location = ""
    var isAllDay = false
    var startAt = Date()
    var endAt = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    var travelTime = "없음"
    var repeatRule = "안 함"
    var calendarIdentifier: String?
    var projectId: UUID?
    var alert = "없음"
    var urlString = ""
    var notes = ""
}

struct EventEditorForm: View {
    @Binding var draft: EventEditorDraft
    let calendars: [CalendarSource]
    let projects: [Project]

    var body: some View {
        Form {
            Section("이벤트") {
                TextField("제목", text: $draft.title)
                TextField("위치 또는 영상 통화", text: $draft.location)
                Toggle("하루종일", isOn: $draft.isAllDay)
                DatePicker("시작", selection: $draft.startAt, displayedComponents: draft.isAllDay ? [.date] : [.date, .hourAndMinute])
                DatePicker("종료", selection: $draft.endAt, displayedComponents: draft.isAllDay ? [.date] : [.date, .hourAndMinute])
            }

            Section("동기화") {
                Picker("Project", selection: $draft.projectId) {
                    Text("Project 없음").tag(nil as UUID?)
                    ForEach(projects) { project in
                        Text(project.title).tag(project.id as UUID?)
                    }
                }

                Picker("캘린더", selection: $draft.calendarIdentifier) {
                    Text("Project / BLOCK 기본값").tag(nil as String?)
                    ForEach(calendars) { calendar in
                        Text(calendar.title).tag(calendar.id as String?)
                    }
                }
            }

            Section("옵션") {
                Picker("이동 시간", selection: $draft.travelTime) {
                    Text("없음").tag("없음")
                    Text("15분").tag("15분")
                    Text("30분").tag("30분")
                    Text("1시간").tag("1시간")
                }
                Picker("반복", selection: $draft.repeatRule) {
                    Text("안 함").tag("안 함")
                    Text("매일").tag("매일")
                    Text("매주").tag("매주")
                    Text("매월").tag("매월")
                }
                Picker("알림", selection: $draft.alert) {
                    Text("없음").tag("없음")
                    Text("시작 시간").tag("시작 시간")
                    Text("10분 전").tag("10분 전")
                    Text("1시간 전").tag("1시간 전")
                }
            }

            Section("상세") {
                TextField("URL", text: $draft.urlString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                TextField("메모", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...6)
                Text("초대받은 사람과 첨부파일은 MVP에서 직접 편집하지 않습니다. 필요한 내용은 메모에 남깁니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
