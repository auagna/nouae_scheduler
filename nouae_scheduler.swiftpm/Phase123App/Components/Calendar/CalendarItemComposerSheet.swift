import SwiftUI

private enum CalendarComposerMode: String, CaseIterable, Identifiable {
    case event = "이벤트"
    case reminder = "미리 알림"

    var id: String { rawValue }
}

struct CalendarItemComposerSheet: View {
    let calendars: [CalendarSource]
    let reminderLists: [ReminderListSource]
    let projects: [Project]
    let onCreateEvent: (EventEditorDraft) async -> Void
    let onCreateReminder: (ReminderEditorDraft) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mode: CalendarComposerMode = .event
    @State private var eventDraft: EventEditorDraft
    @State private var reminderDraft: ReminderEditorDraft
    @State private var isSaving = false

    init(
        selectedDate: Date,
        calendars: [CalendarSource],
        reminderLists: [ReminderListSource],
        projects: [Project],
        onCreateEvent: @escaping (EventEditorDraft) async -> Void,
        onCreateReminder: @escaping (ReminderEditorDraft) async -> Void
    ) {
        self.calendars = calendars
        self.reminderLists = reminderLists
        self.projects = projects
        self.onCreateEvent = onCreateEvent
        self.onCreateReminder = onCreateReminder

        let startAt = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let endAt = Calendar.current.date(byAdding: .hour, value: 1, to: startAt) ?? startAt
        _eventDraft = State(initialValue: EventEditorDraft(startAt: startAt, endAt: endAt))
        _reminderDraft = State(initialValue: ReminderEditorDraft(dueAt: startAt))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Item Type", selection: $mode) {
                    ForEach(CalendarComposerMode.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch mode {
                case .event:
                    EventEditorForm(draft: $eventDraft, calendars: calendars, projects: projects)
                case .reminder:
                    ReminderEditorForm(draft: $reminderDraft, reminderLists: reminderLists, projects: projects)
                }
            }
            .navigationTitle("새 항목")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("저장")
                        }
                    }
                    .disabled(isSaving || currentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var currentTitle: String {
        switch mode {
        case .event: return eventDraft.title
        case .reminder: return reminderDraft.title
        }
    }

    private func save() async {
        isSaving = true
        switch mode {
        case .event:
            await onCreateEvent(eventDraft)
        case .reminder:
            await onCreateReminder(reminderDraft)
        }
        isSaving = false
        dismiss()
    }
}
