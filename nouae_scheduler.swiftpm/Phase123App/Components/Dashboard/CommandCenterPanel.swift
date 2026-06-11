import SwiftUI

struct CommandCenterPanel: View {
    let mission: String
    let nextAction: WorkBlock?
    let blocks: [WorkBlock]
    let projects: [Project]

    var body: some View {
        AppPanel(title: "Command Center", subtitle: "지금 움직일 흐름") {
            VStack(alignment: .leading, spacing: AppUI.Spacing.card) {
                CurrentMissionCard(text: mission)

                if let nextAction {
                    NextActionCard(block: nextAction, projectTitle: projectTitle(for: nextAction))
                } else {
                    AppCard {
                        VStack(alignment: .leading, spacing: 6) {
                            AppSectionHeader(title: "Next Action", subtitle: "가장 가까운 실행 단위")
                            Text("오늘 배치된 다음 행동이 없습니다.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                TodayBlocksCompactList(blocks: blocks, projects: projects)
                DeepWorkPlaceholder()
            }
        }
    }

    private func projectTitle(for block: WorkBlock) -> String? {
        projects.first { $0.id == block.projectId }?.title
    }
}

private struct CurrentMissionCard: View {
    let text: String

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 4)
                VStack(alignment: .leading, spacing: 8) {
                    AppSectionHeader(title: "Current Mission", subtitle: "오늘 운영 문장")
                    Text(text)
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct NextActionCard: View {
    let block: WorkBlock
    let projectTitle: String?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 9) {
                AppSectionHeader(title: "Next Action", subtitle: "가장 가까운 실행 단위") {
                    StatusBadge(block.executionState.title, tone: .blue)
                }
                Text(block.title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let projectTitle {
                    StatusBadge(projectTitle, tone: .purple, symbolName: "folder")
                }
            }
        }
    }

    private var timeText: String {
        "\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))"
    }
}

private struct TodayBlocksCompactList: View {
    let blocks: [WorkBlock]
    let projects: [Project]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                AppSectionHeader(title: "Today Blocks", subtitle: "오늘 시간 위에 놓인 WorkBlock")
                    .padding(.bottom, 6)

                if blocks.isEmpty {
                    Text("오늘 배치된 WorkBlock이 없습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 10)
                }

                ForEach(Array(blocks.prefix(8).enumerated()), id: \.element.id) { index, block in
                    AppListRow(
                        title: block.title,
                        subtitle: timeText(for: block),
                        showsSeparator: index < min(blocks.count, 8) - 1
                    ) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(projectColor(for: block))
                            .frame(width: 5, height: 28)
                    } trailing: {
                        StatusBadge(block.executionState.title, tone: tone(for: block.executionState))
                    }
                }
            }
        }
    }

    private func project(for block: WorkBlock) -> Project? {
        projects.first { $0.id == block.projectId }
    }

    private func projectColor(for block: WorkBlock) -> Color {
        Color(calendarHex: project(for: block)?.calendarColorHex)
    }

    private func timeText(for block: WorkBlock) -> String {
        "\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))"
    }

    private func tone(for state: WorkBlockState) -> StatusBadge.Tone {
        switch state {
        case .planned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .delayed: return .neutral
        case .stopped: return .red
        }
    }
}

private struct DeepWorkPlaceholder: View {
    var body: some View {
        AppCard {
            HStack {
                Label("Deep Work Timer", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("ready later")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
