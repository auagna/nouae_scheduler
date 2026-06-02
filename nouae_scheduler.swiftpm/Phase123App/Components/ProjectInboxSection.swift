import SwiftData
import SwiftUI

struct ProjectInboxSection: View {
    let project: Project
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @State private var title = ""

    var body: some View {
        Section("Inbox") {
            HStack { TextField("RawTask 추가", text: $title); Button { add() } label: { Image(systemName: "plus.circle.fill") }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            ForEach(tasks.filter { $0.projectId == project.id && !$0.isConvertedToBlock }) { task in Text(task.title) }
        }
    }
    private func add() { let value = title; title = ""; try? stores.rawTaskStore.createRawTask(title: value, projectId: project.id) }
}
