import SwiftUI

enum ProjectCalendarConnectionMode: String, CaseIterable, Identifiable {
    case none = "연결 안 함"
    case existing = "기존 캘린더"
    case createNew = "새 캘린더 생성"

    var id: String { rawValue }
}

struct AddProjectView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @ObservedObject var projectStore: ProjectStore
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: ScheduleCategory = .work
    @State private var note = ""
    @State private var connectionMode: ProjectCalendarConnectionMode = .none
    @State private var calendarSources: [CalendarSource] = []
    @State private var selectedCalendarId: String?
    @State private var isLoadingCalendars = false
    @State private var isSaving = false
    @State private var message: String?

    var body: some View {
        Form {
            Section("프로젝트") {
                TextField("프로젝트 이름", text: $title)
                CategoryPicker(selectedCategory: $category)
                TextField("메모", text: $note, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section("Apple Calendar 연결") {
                Picker("연결 방식", selection: $connectionMode) {
                    ForEach(ProjectCalendarConnectionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                if connectionMode == .existing {
                    if isLoadingCalendars {
                        ProgressView("캘린더 불러오는 중...")
                    } else {
                        Picker("캘린더", selection: $selectedCalendarId) {
                            Text("선택 안 함").tag(String?.none)
                            ForEach(calendarSources) { source in
                                Text(source.title).tag(Optional(source.id))
                            }
                        }
                    }
                }

                if connectionMode == .createNew {
                    Text("프로젝트 이름으로 새 Apple Calendar를 만듭니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let message {
                Section {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("프로젝트 추가")
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
        .task {
            await loadCalendarsIfNeeded()
        }
        .onChange(of: connectionMode) { _ in
            Task { await loadCalendarsIfNeeded() }
        }
    }

    private func loadCalendarsIfNeeded() async {
        guard connectionMode == .existing, calendarSources.isEmpty else { return }
        isLoadingCalendars = true
        defer { isLoadingCalendars = false }
        do {
            calendarSources = try await eventKitManager.fetchCalendars()
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let calendarId: String?
            switch connectionMode {
            case .none:
                calendarId = nil
            case .existing:
                calendarId = selectedCalendarId
            case .createNew:
                let created = try await eventKitManager.createCalendar(title: title, category: category)
                calendarId = created?.id
            }

            projectStore.createProject(title: title, category: category, note: note, calendarIdentifier: calendarId)
            onSave()
            dismiss()
        } catch {
            message = error.localizedDescription
        }
    }
}
