import SwiftData
import SwiftUI

struct LogPlaceholderView: View {
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]

    var body: some View {
        NavigationStack {
            List {
                if logs.isEmpty {
                    ContentUnavailableView("Log", systemImage: "square.and.pencil", description: Text("회고 작성 UI는 다음 Phase에서 연결합니다."))
                } else {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.content.isEmpty ? "내용 없음" : log.content)
                            Text(log.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Log")
        }
    }
}
