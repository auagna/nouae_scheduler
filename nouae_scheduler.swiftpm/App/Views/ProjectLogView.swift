import SwiftUI

struct ProjectLogView: View {
    let project: Project
    @ObservedObject var projectStore: ProjectStore

    @State private var title = ""
    @State private var content = ""
    @State private var mood = ""
    @State private var linkedWorkBlockId: UUID?

    private var blocks: [TimeBlock] {
        projectStore.blocks(for: project)
    }

    var body: some View {
        List {
            Section("새 로그") {
                TextField("제목", text: $title)
                TextField("내용", text: $content, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                TextField("기분/컨디션", text: $mood)
                Picker("연결 WorkBlock", selection: $linkedWorkBlockId) {
                    Text("연결 없음").tag(UUID?.none)
                    ForEach(blocks) { block in
                        Text(block.title).tag(Optional(block.id))
                    }
                }
                Button("로그 작성") {
                    projectStore.addLog(project: project, title: title, content: content, mood: mood.isEmpty ? nil : mood, linkedWorkBlockId: linkedWorkBlockId)
                    title = ""
                    content = ""
                    mood = ""
                    linkedWorkBlockId = nil
                }
            }

            Section("최근 로그") {
                let logs = projectStore.logs(for: project)
                if logs.isEmpty {
                    Text("아직 작성한 로그가 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(log.title)
                                .font(.headline)
                            Text(log.content)
                                .font(.callout)
                            HStack {
                                Text(dateText(log.createdAt))
                                if let mood = log.mood, !mood.isEmpty { Text("· \(mood)") }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Logs")
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
