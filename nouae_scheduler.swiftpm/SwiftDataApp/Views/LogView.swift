import SwiftData
import SwiftUI

struct LogView: View {
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt, order: .reverse) private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @State private var projectId: UUID?
    @State private var workBlockId: UUID?
    @State private var focusLevel = 3
    @State private var blockerTags = ""
    @State private var blockerNote = ""
    @State private var adjustment = ""
    @State private var content = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("오늘 회고") {
                    Picker("프로젝트", selection: $projectId) { Text("미연결").tag(UUID?.none); ForEach(projects.filter { !$0.isArchived }) { Text($0.title).tag(UUID?.some($0.id)) } }
                    Picker("WorkBlock", selection: $workBlockId) { Text("미연결").tag(UUID?.none); ForEach(blocks.prefix(20)) { Text($0.title).tag(UUID?.some($0.id)) } }
                    Stepper("집중도 \(focusLevel)", value: $focusLevel, in: 1...5)
                    TextField("막힌 원인 태그, 쉼표로 구분", text: $blockerTags)
                    TextField("막힌 원인 메모", text: $blockerNote, axis: .vertical)
                    TextField("다음 조정", text: $adjustment, axis: .vertical)
                    TextField("자유 회고", text: $content, axis: .vertical)
                    Button("로그 저장") { save() }
                }
                Section("최근 로그") {
                    ForEach(logs.prefix(10)) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.content.isEmpty ? "회고 메모 없음" : log.content)
                            Text(log.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Log")
        }
    }

    private func save() {
        let tags = blockerTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        try? stores.logStore.createLog(projectId: projectId, workBlockId: workBlockId, focusLevel: focusLevel, blockerTags: tags, blockerNote: blockerNote, nextAdjustment: adjustment, content: content)
        blockerTags = ""; blockerNote = ""; adjustment = ""; content = ""
    }
}
