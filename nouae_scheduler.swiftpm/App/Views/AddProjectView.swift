import SwiftUI

enum ProjectCalendarConnectionMode: String, CaseIterable, Identifiable {
    case categoryDefault = "카테고리 캘린더 자동"
    case existing = "기존 캘린더"
    case createNew = "새 캘린더 생성"
    case none = "아직 연결하지 않음"

    var id: String { rawValue }
}

struct AddProjectView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @ObservedObject var projectStore: ProjectStore
    @ObservedObject var calendarSelectionStore: CalendarSelectionStore
    let calendarSources: [CalendarSource]
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var type: ProjectType = .work
    @State private var category: ScheduleCategory = .work
    @State private var purpose = ""
    @State private var note = ""
    @State private var connectionMode: ProjectCalendarConnectionMode = .categoryDefault
    @State private var loadedCalendarSources: [CalendarSource] = []
    @State private var selectedCalendarId: String?
    @State private var isLoadingCalendars = false
    @State private var isSaving = false
    @State private var message: String?

    private var availableCalendars: [CalendarSource] {
        loadedCalendarSources.isEmpty ? calendarSources : loadedCalendarSources
    }

    var body: some View {
        Form {
            Section("프로젝트") {
                TextField("프로젝트 이름", text: $title)
                Picker("성격", selection: $type) {
                    ForEach(ProjectType.allCases) { type in Text(type.rawValue).tag(type) }
                }
                CategoryPicker(selectedCategory: $category)
                TextField("목적", text: $purpose, axis: .vertical).lineLimit(2, reservesSpace: true)
                TextField("메모", text: $note, axis: .vertical).lineLimit(3, reservesSpace: true)
            }

            Section("Apple Calendar 연결") {
                Picker("연결 방식", selection: $connectionMode) {
                    ForEach(ProjectCalendarConnectionMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                }

                if connectionMode == .categoryDefault {
                    Text(categoryCalendarStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if connectionMode == .existing {
                    if isLoadingCalendars {
                        ProgressView("캘린더 불러오는 중...")
                    } else {
                        Picker("캘린더", selection: $selectedCalendarId) {
                            Text("선택 안 함").tag(String?.none)
                            ForEach(availableCalendars) { source in Text(source.title).tag(Optional(source.id)) }
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
                Section { Text(message).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("프로젝트 추가")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "저장 중" : "저장") { Task { await save() } }
                    .disabled(isSaving)
            }
        }
        .task { await loadCalendarsIfNeeded() }
        .onChange(of: connectionMode) { _ in Task { await loadCalendarsIfNeeded() } }
        .onChange(of: category) { _ in selectedCalendarId = nil }
    }

    private var categoryCalendarStatus: String {
        if let title = calendarSelectionStore.calendarTitle(for: category, in: availableCalendars) {
            return "\(category.rawValue) 카테고리는 \"\(title)\" 캘린더에 저장됩니다."
        }
        return "\(category.rawValue) 카테고리에 연결된 캘린더가 없습니다. Calendar 탭 필터에서 매핑해 주세요."
    }

    private func loadCalendarsIfNeeded() async {
        guard availableCalendars.isEmpty || connectionMode == .existing else { return }
        isLoadingCalendars = true
        defer { isLoadingCalendars = false }
        do {
            loadedCalendarSources = try await eventKitManager.fetchCalendars()
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
            case .categoryDefault:
                calendarId = calendarSelectionStore.calendarId(for: category, in: availableCalendars)
            case .none:
                calendarId = nil
            case .existing:
                calendarId = selectedCalendarId
            case .createNew:
                let created = try await eventKitManager.createCalendar(title: title, category: category)
                calendarId = created?.id
                if let calendarId {
                    calendarSelectionStore.setCalendarSource(calendarId, for: category)
                }
            }

            guard projectStore.createProject(title: title, type: type, category: category, purpose: purpose, note: note, calendarIdentifier: calendarId) != nil else {
                message = projectStore.message
                return
            }
            onSave()
            dismiss()
        } catch {
            message = error.localizedDescription
        }
    }
}
