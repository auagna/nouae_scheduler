import SwiftData
import SwiftUI

struct PlanPlaceholderView: View {
    @Query private var tasks: [RawTask]
    @Query private var blocks: [WorkBlock]

    var body: some View {
        NavigationStack {
            List {
                Section("RawTask Inbox") {
                    if tasks.filter({ !$0.isConvertedToBlock }).isEmpty { Text("Inbox가 비어 있습니다.").foregroundStyle(.secondary) }
                    ForEach(tasks.filter { !$0.isConvertedToBlock }) { Text($0.title) }
                }
                Section("WorkBlocks") {
                    if blocks.isEmpty { Text("배치된 WorkBlock이 없습니다.").foregroundStyle(.secondary) }
                    ForEach(blocks) { block in
                        VStack(alignment: .leading) {
                            Text(block.title)
                            Text(block.startAt.formatted(date: .omitted, time: .shortened) + " - " + block.endAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Plan")
        }
    }
}
