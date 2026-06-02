import SwiftData
import SwiftUI

struct ProjectTodayWorkSection: View {
    let project: Project
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]
    var body: some View {
        Section("오늘 작업") {
            let items = blocks.filter { $0.projectId == project.id && Calendar.current.isDateInToday($0.startAt) }
            if items.isEmpty { Text("오늘 배치된 WorkBlock이 없습니다.").foregroundStyle(.secondary) }
            ForEach(items) { block in VStack(alignment: .leading) { Text(block.title); Text(block.executionState.title).font(.caption).foregroundStyle(.secondary) } }
        }
    }
}
