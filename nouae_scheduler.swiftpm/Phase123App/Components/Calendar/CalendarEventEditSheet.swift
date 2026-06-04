import SwiftUI

struct CalendarEventEditSheet: View {
    let item: CalendarTimelineItem
    let onSave: (String, Date, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var startAt: Date
    @State private var endAt: Date

    init(item: CalendarTimelineItem, onSave: @escaping (String, Date, Date) -> Void) {
        self.item = item
        self.onSave = onSave
        _title = State(initialValue: item.title)
        _startAt = State(initialValue: item.startAt)
        _endAt = State(initialValue: item.endAt)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Title", text: $title)
                    DatePicker("Start", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(title.trimmingCharacters(in: .whitespacesAndNewlines), startAt, endAt)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || endAt <= startAt)
                }
            }
        }
    }
}
