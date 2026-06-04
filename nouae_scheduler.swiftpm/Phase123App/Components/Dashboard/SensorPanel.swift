import SwiftUI

struct SensorPanel: View {
    let snapshot: DashboardSnapshot
    let lifePulse: Int
    let metrics: [DashboardMetric]
    let projects: [Project]
    let showsLifePulse: Bool

    var body: some View {
        AppPanel(title: "Sensor", subtitle: "현재 상태 감지") {
            VStack(alignment: .leading, spacing: AppUI.Spacing.card) {
                if showsLifePulse {
                    LifePulseCard(value: lifePulse)
                }

                CompactStatusStrip(snapshot: snapshot)
                SensorMetricGrid(metrics: metrics)
                ActiveProjectCompactList(projects: projects)
            }
        }
    }
}

private struct CompactStatusStrip: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppSectionHeader(title: "Status", subtitle: "오늘 운영 집계")
            HStack(spacing: 8) {
                StatusBadge("예정 \(snapshot.planned)", tone: .blue, symbolName: "clock")
                StatusBadge("진행 \(snapshot.inProgress)", tone: .orange, symbolName: "play.fill")
            }
            HStack(spacing: 8) {
                StatusBadge("완료 \(snapshot.completed)", tone: .green, symbolName: "checkmark")
                StatusBadge("미룸 \(snapshot.delayedToday)", tone: .neutral, symbolName: "arrow.uturn.forward")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SensorMetricGrid: View {
    let metrics: [DashboardMetric]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                AppSectionHeader(title: "Metrics", subtitle: "Life Pulse inputs")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(metrics) { metric in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(metric.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(metric.value)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }
}

private struct ActiveProjectCompactList: View {
    let projects: [Project]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                AppSectionHeader(title: "Active Projects", subtitle: "현재 움직이는 프로젝트")
                    .padding(.bottom, 6)

                if projects.isEmpty {
                    Text("active project가 없습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 10)
                }

                ForEach(Array(projects.prefix(5).enumerated()), id: \.element.id) { index, project in
                    AppListRow(
                        title: project.title,
                        subtitle: project.goal.isEmpty ? project.status.title : project.goal,
                        showsSeparator: index < min(projects.count, 5) - 1
                    ) {
                        Circle()
                            .fill(Color(calendarHex: project.calendarColorHex))
                            .frame(width: 10, height: 10)
                    } trailing: {
                        StatusBadge(project.status.title, tone: .neutral)
                    }
                }
            }
        }
    }
}
