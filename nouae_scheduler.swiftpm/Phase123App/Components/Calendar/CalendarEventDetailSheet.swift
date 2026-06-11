import SwiftUI

struct CalendarEventDetailSheet: View {
    let item: CalendarTimelineItem
    let project: Project?
    let onOpenProject: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onImportAsWorkBlock: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    Text(item.title)
                        .font(.headline)
                    Text("\(item.startAt.formatted(date: .abbreviated, time: .shortened)) - \(item.endAt.formatted(date: .abbreviated, time: .shortened))")
                    HStack {
                        Circle()
                            .fill(Color(calendarHex: item.colorHex))
                            .frame(width: 10, height: 10)
                        Text(item.calendarIdentifier ?? "Calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let project {
                    Section("Project") {
                        HStack {
                            Text(project.title)
                            Spacer()
                            StatusBadge("Project", tone: .purple, symbolName: "folder")
                        }
                    }
                }

                Section("Actions") {
                    Button("Edit Event") { dismiss(); onEdit() }
                        .disabled(item.externalEventIdentifier == nil)
                    Button("Import as WorkBlock") { dismiss(); onImportAsWorkBlock() }
                        .disabled(item.workBlockId != nil)
                    Button("Delete Event", role: .destructive) { showingDeleteConfirmation = true }
                        .disabled(item.externalEventIdentifier == nil)
                }
            }
            .navigationTitle("Event Detail")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .confirmationDialog("이 Calendar Event를 삭제할까요?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    dismiss()
                    onDelete()
                }
                Button("취소", role: .cancel) {}
            }
        }
    }
}
