import SwiftData
import SwiftUI

struct ProjectRecentLogSection: View {
    let project: Project
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query private var blocks: [WorkBlock]

    var body: some View {
        Section("최근 로그") {
            let items = logs.filter { $0.projectId == project.id }.prefix(3)
            if items.isEmpty {
                Text("최근 로그가 없습니다.")
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(items)) { log in
                LogEntryCard(
                    log: log,
                    projectTitle: project.title,
                    workBlockTitle: blocks.first { $0.id == log.workBlockId }?.title
                )
            }
        }
    }
}
