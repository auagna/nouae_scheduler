import SwiftData
import SwiftUI

struct LogEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt, order: .reverse) private var blocks: [WorkBlock]

    @State private var logType: LogType = .workBlock
    @State private var projectId: UUID?
    @State private var workBlockId: UUID?
    @State private var title = ""
    @State private var focusLevel = 3
    @State private var moodTags: Set<String> = []
    @State private var blockerTags: Set<String> = []
    @State private var blockerNote = ""
    @State private var nextAdjustment = ""
    @State private var content = ""
    @State private var errorMessage: String?

    init(initialProjectId: UUID? = nil, initialWorkBlockId: UUID? = nil) {
        _projectId = State(initialValue: initialProjectId)
        _workBlockId = State(initialValue: initialWorkBlockId)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preset") {
                    Picker("Log Type", selection: $logType) {
                        ForEach(LogType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    TextField("제목", text: $title)
                }

                Section("연결") {
                    Picker("프로젝트", selection: $projectId) {
                        Text("프로젝트 없음").tag(nil as UUID?)
                        ForEach(activeProjects) { project in
                            Text(project.title).tag(project.id as UUID?)
                        }
                    }
                    Picker("WorkBlock", selection: $workBlockId) {
                        Text("연결 안 함").tag(nil as UUID?)
                        ForEach(filteredBlocks) { block in
                            Text(block.title).tag(block.id as UUID?)
                        }
                    }
                }

                Section("집중도") {
                    Picker("집중도", selection: $focusLevel) {
                        ForEach(1...5, id: \.self) { level in Text("\(level)").tag(level) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Mood Quick Check") {
                    ForEach(LogTaxonomy.moodGroups) { group in
                        DisclosureGroup(group.title) {
                            ForEach(group.tags, id: \.self) { option in
                                Toggle(option, isOn: binding(for: option, in: $moodTags))
                            }
                        }
                    }
                }

                Section("막힌 원인") {
                    ForEach(LogTaxonomy.blockerGroups) { group in
                        DisclosureGroup(group.title) {
                            ForEach(group.tags, id: \.self) { option in
                                Toggle(option, isOn: binding(for: option, in: $blockerTags))
                            }
                        }
                    }
                    TextField("메모", text: $blockerNote, axis: .vertical)
                }

                Section("다음 조정") {
                    TextField("다음에 바꿀 한 가지", text: $nextAdjustment, axis: .vertical)
                }

                Section("짧은 회고") {
                    TextField("오늘 작업에서 남길 내용", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Log 작성")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("저장") { save() } }
            }
        }
    }

    private var activeProjects: [Project] { projects.filter { $0.status != .archived } }
    private var filteredBlocks: [WorkBlock] {
        guard let projectId else { return blocks }
        return blocks.filter { $0.projectId == projectId }
    }

    private func binding(for option: String, in selection: Binding<Set<String>>) -> Binding<Bool> {
        Binding(
            get: { selection.wrappedValue.contains(option) },
            set: { selected in
                var values = selection.wrappedValue
                if selected { values.insert(option) }
                else { values.remove(option) }
                selection.wrappedValue = values
            }
        )
    }

    private func save() {
        do {
            try stores.logStore.createLog(
                logType: logType,
                areaId: activeProjects.first(where: { $0.id == projectId })?.areaId,
                projectId: projectId,
                workBlockId: workBlockId,
                title: title,
                focusLevel: focusLevel,
                moodTags: Array(moodTags).sorted(),
                blockerTags: Array(blockerTags).sorted(),
                blockerNote: blockerNote,
                nextAdjustment: nextAdjustment,
                content: content
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
