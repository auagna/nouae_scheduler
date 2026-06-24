import SwiftUI

struct WeeklyRoutineSummaryModule: NouAENativeModule {
    let manifest = ModuleManifest(
        id: "builtIn.weeklyRoutineSummary",
        name: "Weekly Routine Summary",
        descriptionText: "이번 주 Routine 흐름을 작은 카드로 요약합니다.",
        category: .routine,
        iconSystemName: "repeat.circle",
        origin: .builtIn,
        placements: [.dashboardCompact, .projectDashboardContext],
        capabilities: [.readRoutines, .readTrackerSummary],
        entryType: .native,
        isEnabledByDefault: true
    )

    func makeView(context: ModuleContext) -> AnyView {
        AnyView(WeeklyRoutineSummaryModuleView(context: context))
    }

    func handle(action: ModuleAction, context: ModuleContext) async throws {
        throw ModuleError.actionFailed("Weekly Routine Summary는 읽기 전용 Module입니다.")
    }
}

private struct WeeklyRoutineSummaryModuleView: View {
    let context: ModuleContext

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Weekly Routine Summary", systemImage: "repeat.circle")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 10) {
                    metric("Routines", value: "\(scopedRoutines.count)")
                    metric("Blocks", value: "\(weekBlocks.count)")
                    metric("Done", value: "\(completedBlocks.count)")
                }
            }
        }
    }

    private var scopedRoutines: [Routine] {
        context.routines.filter { routine in
            routine.isActive && (context.selectedProjectId == nil || routine.projectId == context.selectedProjectId)
        }
    }

    private var weekBlocks: [WorkBlock] {
        let start = Calendar.current.dateInterval(of: .weekOfYear, for: context.currentDate)?.start ?? context.currentDate
        return context.workBlocks.filter { block in
            block.startAt >= start && (context.selectedProjectId == nil || block.projectId == context.selectedProjectId)
        }
    }

    private var completedBlocks: [WorkBlock] {
        weekBlocks.filter { $0.executionState == .completed }
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline)
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProjectReviewShortcutModule: NouAENativeModule {
    let manifest = ModuleManifest(
        id: "builtIn.projectReviewShortcut",
        name: "Project Review Shortcut",
        descriptionText: "Project의 미배치 Task를 보고 빠른 회고를 남깁니다.",
        category: .reflection,
        iconSystemName: "square.and.pencil",
        origin: .builtIn,
        placements: [.projectDashboardContext],
        capabilities: [.readTasks, .createLog],
        entryType: .native,
        isEnabledByDefault: true
    )

    func makeView(context: ModuleContext) -> AnyView {
        AnyView(ProjectReviewShortcutModuleView(context: context))
    }

    func handle(action: ModuleAction, context: ModuleContext) async throws {
        try await context.actionRouter?.handle(action, context: context)
    }
}

private struct ProjectReviewShortcutModuleView: View {
    let context: ModuleContext
    @State private var message: String?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Project Review Shortcut", systemImage: "square.and.pencil")
                    .font(.subheadline.weight(.semibold))
                Text("Review 필요 Task \(reviewTasks.count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Quick Log 생성") {
                    Task { @MainActor in
                        do {
                            try await context.actionRouter?.handle(
                                ModuleAction(type: .createLog, title: "Project Review", payload: ["content": "Project review shortcut에서 생성한 짧은 회고입니다."]),
                                context: context
                            )
                            message = "Log를 생성했습니다."
                        } catch {
                            message = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(.bordered)
                if let message {
                    Text(message).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var reviewTasks: [RawTask] {
        context.tasks.filter { task in
            !task.isConvertedToBlock && (context.selectedProjectId == nil || task.projectId == context.selectedProjectId)
        }
    }
}
