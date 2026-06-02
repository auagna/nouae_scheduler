import SwiftData
import SwiftUI

struct CalendarPlaceholderView: View { var body: some View { NavigationStack { ContentUnavailableView("Calendar", systemImage: "calendar", description: Text("Calendar 흐름 보기는 다음 Phase에서 연결합니다.")).navigationTitle("Calendar") } } }

struct PlanView: View {
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    var body: some View { NavigationStack { List { Section("RawTask Inbox") { if tasks.filter({ !$0.isConvertedToBlock }).isEmpty { Text("Inbox가 비어 있습니다.").foregroundStyle(.secondary) }; ForEach(tasks.filter { !$0.isConvertedToBlock }) { Text($0.title) } } }.navigationTitle("Plan") } }
}

struct LogView: View {
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    var body: some View { NavigationStack { List(logs) { log in Text(log.content.isEmpty ? "내용 없음" : log.content) }.navigationTitle("Log") } }
}
