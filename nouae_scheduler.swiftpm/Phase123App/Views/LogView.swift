import SwiftData
import SwiftUI

struct LogView: View {
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \WorkBlock.startAt, order: .reverse) private var blocks: [WorkBlock]

    @State private var showingEditor = false
    @State private var logType: LogType = .daily
    @State private var projectId: UUID?
    @State private var focusLevel = 3
    @State private var moodTags: Set<String> = []
    @State private var blockerTags: Set<String> = []
    @State private var nextAdjustment = ""
    @State private var content = ""
    @State private var projectFilterId: UUID?
    @State private var message: String?
    @State private var showingPromptExport = false

    var body: some View {
        NavigationStack {
            AppScreenContainer(spacing: 18) {
                AppPageHeader(title: "Log", subtitle: "1분 안에 남기는 reflection data입니다.") {
                    HStack(spacing: 8) {
                        Button { showingPromptExport = true } label: {
                            Image(systemName: "doc.on.clipboard")
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Log Pattern Prompt")

                        Button { showingEditor = true } label: {
                            Image(systemName: "plus")
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Log 작성")
                    }
                }

                quickLogPanel
                reflectionSummaryPanel
                todayLogsPanel
                projectLogsPanel
                timelinePanel
            }
            .sheet(isPresented: $showingEditor) { LogEditorSheet() }
            .sheet(isPresented: $showingPromptExport) {
                PromptExportView(initialType: .logPatternReview, selectedProjectId: projectFilterId)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var quickLogPanel: some View {
        AppPanel(title: "Quick Log", subtitle: "짧은 상태 태그와 다음 조정만 남깁니다.") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Log Type", selection: $logType) {
                    ForEach(LogType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.menu)

                Picker("Project", selection: $projectId) {
                    Text("프로젝트 없음").tag(nil as UUID?)
                    ForEach(activeProjects) { project in
                        Text(project.title).tag(project.id as UUID?)
                    }
                }

                Picker("Focus", selection: $focusLevel) {
                    ForEach(1...5, id: \.self) { level in
                        Text("\(level)").tag(level)
                    }
                }
                .pickerStyle(.segmented)

                groupedTagSection(title: "Mood Quick Check", groups: LogTaxonomy.moodGroups, selection: $moodTags)
                groupedTagSection(title: "Blocker Quick Check", groups: LogTaxonomy.blockerGroups, selection: $blockerTags)

                TextField("다음 조정", text: $nextAdjustment, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                TextField("짧은 회고", text: $content, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)

                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    saveQuickLog()
                } label: {
                    Label("Log 저장", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && nextAdjustment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var reflectionSummaryPanel: some View {
        AppPanel(title: "Reflection Summary", subtitle: "이번 주 기록 패턴입니다.") {
            HStack(spacing: 10) {
                summaryCard("Logs", value: "\(weekLogs.count)")
                summaryCard("Avg Focus", value: averageFocusText)
                summaryCard("Mood", value: topMood ?? "-")
                summaryCard("Blocker", value: topBlocker ?? "-")
            }
        }
    }

    private var todayLogsPanel: some View {
        AppPanel(title: "Today Logs", subtitle: "오늘 직접 남긴 회고입니다.") {
            if todayLogs.isEmpty {
                Text("오늘 작성한 Log가 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todayLogs.prefix(3)) { log in
                    LogEntryCard(log: log, projectTitle: titleForProject(log.projectId), workBlockTitle: titleForBlock(log.workBlockId))
                    AppDivider()
                }
            }
        }
    }

    private var projectLogsPanel: some View {
        AppPanel(title: "Project Logs", subtitle: "프로젝트별 회고를 빠르게 필터링합니다.") {
            Picker("Project Filter", selection: $projectFilterId) {
                Text("전체").tag(nil as UUID?)
                ForEach(activeProjects) { project in
                    Text(project.title).tag(project.id as UUID?)
                }
            }
            .pickerStyle(.menu)

            ForEach(filteredProjectLogs.prefix(4)) { log in
                LogEntryCard(log: log, projectTitle: titleForProject(log.projectId), workBlockTitle: titleForBlock(log.workBlockId))
                AppDivider()
            }
        }
    }

    private var timelinePanel: some View {
        AppPanel(title: "Log Timeline", subtitle: "날짜별 reflection trail입니다.") {
            if logs.isEmpty {
                ContentUnavailableView("작성한 Log가 없습니다", systemImage: "square.and.pencil", description: Text("작업을 돌아보고 필요한 조정만 짧게 남겨 보세요."))
            } else {
                ForEach(logs.prefix(12)) { log in
                    LogEntryCard(log: log, projectTitle: titleForProject(log.projectId), workBlockTitle: titleForBlock(log.workBlockId))
                    AppDivider()
                }
            }
        }
    }

    private func groupedTagSection(title: String, groups: [LogTagGroup], selection: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 5) {
                    Text(group.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    FlowLayout(alignment: .leading, spacing: 8) {
                        ForEach(group.tags, id: \.self) { option in
                            Button {
                                var values = selection.wrappedValue
                                if values.contains(option) {
                                    values.remove(option)
                                } else {
                                    values.insert(option)
                                }
                                selection.wrappedValue = values
                            } label: {
                                Text(option)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selection.wrappedValue.contains(option) ? Color.accentColor.opacity(0.16) : Color(uiColor: .tertiarySystemGroupedBackground), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func summaryCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var activeProjects: [Project] { projects.filter { $0.status != .archived } }
    private var todayLogs: [ProjectLog] { logs.filter { Calendar.current.isDateInToday($0.createdAt) } }
    private var weekLogs: [ProjectLog] {
        let start = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return logs.filter { $0.createdAt >= start }
    }
    private var filteredProjectLogs: [ProjectLog] {
        guard let projectFilterId else { return logs }
        return logs.filter { $0.projectId == projectFilterId }
    }
    private var averageFocusText: String {
        let values = weekLogs.compactMap(\.focusLevel)
        guard !values.isEmpty else { return "-" }
        let average = Double(values.reduce(0, +)) / Double(values.count)
        return String(format: "%.1f", average)
    }
    private var topMood: String? { topFrequency(weekLogs.flatMap(\.moodTags)) }
    private var topBlocker: String? { topFrequency(weekLogs.flatMap(\.blockerTags)) }

    private func topFrequency(_ values: [String]) -> String? {
        Dictionary(grouping: values, by: { $0 })
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
            .first?.0
    }

    private func titleForProject(_ id: UUID?) -> String? {
        guard let id else { return nil }
        return projects.first { $0.id == id }?.title
    }

    private func titleForBlock(_ id: UUID?) -> String? {
        guard let id else { return nil }
        return blocks.first { $0.id == id }?.title
    }

    private func saveQuickLog() {
        do {
            try stores.logStore.createLog(
                logType: logType,
                areaId: activeProjects.first(where: { $0.id == projectId })?.areaId,
                projectId: projectId,
                workBlockId: nil,
                title: logType.title,
                focusLevel: focusLevel,
                moodTags: Array(moodTags).sorted(),
                blockerTags: Array(blockerTags).sorted(),
                blockerNote: "",
                nextAdjustment: nextAdjustment,
                content: content
            )
            nextAdjustment = ""
            content = ""
            moodTags.removeAll()
            blockerTags.removeAll()
            message = "Log를 저장했습니다."
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct FlowLayout<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    private let content: Content

    init(alignment: HorizontalAlignment, spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: spacing, alignment: .leading)], alignment: alignment, spacing: spacing) {
            content
        }
    }
}
