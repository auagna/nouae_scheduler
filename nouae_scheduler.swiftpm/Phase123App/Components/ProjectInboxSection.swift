import SwiftData
import SwiftUI

struct ProjectInboxSection: View {
    let project: Project
    @EnvironmentObject private var stores: AppStores
    @EnvironmentObject private var services: AppServices
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @State private var title = ""

    var body: some View {
        Section("Inbox") {
            HStack {
                TextField("RawTask 추가", text: $title)
                Button { add() } label: { Image(systemName: "plus.circle.fill") }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ForEach(tasks.filter { $0.projectId == project.id && stores.rawTaskStore.isVisibleInInbox($0) }) { task in
                HStack {
                    Text(task.title)
                    Spacer()
                    SyncStatusBadge(state: task.syncState)
                }
            }
        }
    }

    private func add() {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        title = ""
        guard let task = try? stores.rawTaskStore.createRawTask(title: value, projectId: project.id) else { return }
        Task { try? await services.reminderSync.exportRawTask(task) }
    }
}
