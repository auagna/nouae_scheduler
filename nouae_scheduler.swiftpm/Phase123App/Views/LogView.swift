import SwiftData
import SwiftUI

struct LogView: View {
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query private var projects: [Project]
    @Query private var blocks: [WorkBlock]
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            List {
                if logs.isEmpty {
                    ContentUnavailableView("작성한 Log가 없습니다", systemImage: "square.and.pencil", description: Text("작업을 돌아보고 필요한 조정만 짧게 남겨 보세요."))
                }
                ForEach(logs) { log in
                    LogEntryCard(
                        log: log,
                        projectTitle: projects.first { $0.id == log.projectId }?.title,
                        workBlockTitle: blocks.first { $0.id == log.workBlockId }?.title
                    )
                }
            }
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log 작성")
                }
            }
            .sheet(isPresented: $showingEditor) { LogEditorSheet() }
        }
    }
}
