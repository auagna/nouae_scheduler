import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    let calendarTitle: String?
    @ObservedObject var projectStore: ProjectStore

    private var summary: ProjectDashboardSummary {
        projectStore.summary(for: project)
    }

    private var blocks: [TimeBlock] {
        projectStore.blocks(for: project)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.title)
                        .font(.title2.weight(.bold))
                    Label(project.category.rawValue, systemImage: project.category.symbolName)
                        .foregroundStyle(project.category.color)
                    Text(calendarTitle ?? "캘린더 미연결")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let note = project.note, !note.isEmpty {
                        Text(note)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("대시보드") {
                ProjectDashboardPanel(summary: summary)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 6)
            }

            Section("연결된 TimeBlock") {
                if blocks.isEmpty {
                    Text("아직 연결된 TimeBlock이 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(blocks) { block in
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
                }
            }

            Section {
                Button(role: .destructive) {
                    projectStore.archive(project)
                } label: {
                    Label("프로젝트 보관", systemImage: "archivebox")
                }
            }
        }
        .navigationTitle("Project")
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
