import SwiftUI
import UIKit

struct ProjectDetailView: View {
    let project: Project
    let calendarTitle: String?
    @ObservedObject var projectStore: ProjectStore

    @State private var rawTaskTitle = ""
    @State private var rawTaskMemo = ""
    @State private var adjustmentText = ""
    @State private var copiedPrompt = false

    private var currentProject: Project {
        projectStore.project(id: project.id) ?? project
    }

    private var summary: ProjectDashboardSummary {
        projectStore.summary(for: currentProject)
    }

    private var blocks: [TimeBlock] {
        projectStore.blocks(for: currentProject)
    }

    var body: some View {
        List {
            Section("Project Summary") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentProject.title)
                        .font(.title2.weight(.bold))
                    HStack {
                        Label(currentProject.category.rawValue, systemImage: currentProject.category.symbolName)
                        Text(currentProject.type.rawValue)
                        Text(currentProject.status.rawValue)
                    }
                    .font(.caption)
                    .foregroundStyle(currentProject.category.color)

                    Picker("상태", selection: Binding(
                        get: { currentProject.status },
                        set: { projectStore.updateStatus($0, for: currentProject) }
                    )) {
                        ForEach(ProjectStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    Text(calendarTitle ?? "캘린더 미연결")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Project Brief") {
                if currentProject.purpose.isEmpty && (currentProject.note ?? "").isEmpty {
                    Text("목적과 메모가 아직 비어 있습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    if !currentProject.purpose.isEmpty {
                        Text(currentProject.purpose)
                    }
                    if let note = currentProject.note, !note.isEmpty {
                        Text(note)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Dashboard") {
                ProjectDashboardPanel(summary: summary)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 6)
            }

            Section("Today Work") {
                let todayBlocks = blocks.filter { Calendar.current.isDateInToday($0.startAt) }
                if todayBlocks.isEmpty {
                    Text("오늘 배치된 WorkBlock이 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(todayBlocks) { block in
                        workBlockRow(block)
                    }
                }
            }

            Section("RawTask Inbox") {
                TextField("아직 시간에 배치하지 않은 작업", text: $rawTaskTitle)
                TextField("메모", text: $rawTaskMemo, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                Button("RawTask 추가") {
                    projectStore.addRawTask(title: rawTaskTitle, memo: rawTaskMemo, project: currentProject)
                    rawTaskTitle = ""
                    rawTaskMemo = ""
                }

                ForEach(projectStore.rawTasks(for: currentProject)) { task in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                        if let memo = task.memo, !memo.isEmpty {
                            Text(memo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Project Page") {
                NavigationLink("페이지 편집") {
                    ProjectPageEditor(project: currentProject, projectStore: projectStore)
                }
                ForEach(projectStore.pageSections(for: currentProject).prefix(3)) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                            .font(.headline)
                        Text(section.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
            }

            Section("Recent Logs") {
                NavigationLink("로그 작성 / 보기") {
                    ProjectLogView(project: currentProject, projectStore: projectStore)
                }
                ForEach(projectStore.logs(for: currentProject).prefix(3)) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.title)
                            .font(.headline)
                        Text(log.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            Section("Next Adjustment") {
                if let adjustment = projectStore.activeAdjustment(for: currentProject) {
                    Text(adjustment.content)
                }
                TextField("다음 조정 내용을 입력", text: $adjustmentText, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                Button("Next Adjustment 저장") {
                    projectStore.setNextAdjustment(project: currentProject, content: adjustmentText)
                    adjustmentText = ""
                }
            }

            Section("AI Brief Prompt Export") {
                Button(copiedPrompt ? "복사됨" : "프롬프트 복사") {
                    UIPasteboard.general.string = projectStore.aiBriefPrompt(for: currentProject)
                    copiedPrompt = true
                }
            }

            Section("Report Preview") {
                let report = projectStore.reportSummary(for: currentProject)
                VStack(alignment: .leading, spacing: 6) {
                    Text(report.headline)
                        .font(.headline)
                    Text("작업 시간: \(minutesText(report.workMinutes))")
                    Text("RawTask: \(report.rawTaskCount)개 · Logs: \(report.logCount)개")
                    Text("Next: \(report.activeAdjustment ?? "없음")")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            Section {
                Button(role: .destructive) {
                    projectStore.archive(currentProject)
                } label: {
                    Label("프로젝트 보관", systemImage: "archivebox")
                }
            }
        }
        .navigationTitle("Project")
    }

    private func workBlockRow(_ block: TimeBlock) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.title)
                .font(.headline)
            Text("\(dateText(block.startAt)) - \(timeText(block.endAt))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(block.durationMinutes)분 · \(block.syncStatus.label)")
                .font(.caption2)
                .foregroundStyle(block.category.color)
        }
    }

    private func minutesText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours == 0 { return "\(remaining)분" }
        if remaining == 0 { return "\(hours)시간" }
        return "\(hours)시간 \(remaining)분"
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
