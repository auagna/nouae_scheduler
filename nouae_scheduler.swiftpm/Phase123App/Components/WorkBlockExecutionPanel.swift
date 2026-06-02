import Foundation
import SwiftUI

enum WorkBlockAction {
    case start
    case complete
    case delay
    case stop
}

struct WorkBlockExecutionPanel: View {
    let blocks: [WorkBlock]
    let projects: [Project]
    let onAction: (WorkBlock, WorkBlockAction) -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            if let item = panelItem(at: timeline.date) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Label(item.title, systemImage: item.icon)
                                .font(.headline)
                            Spacer()
                            Text(item.block.executionState.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(item.block.title)
                            .font(.subheadline.weight(.semibold))
                        if let project = projects.first(where: { $0.id == item.block.projectId }) {
                            Text(project.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if !item.block.memo.isEmpty {
                            Text(item.block.memo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        if item.mode == .running {
                            Text(remainingText(block: item.block, now: timeline.date))
                                .font(.title3.monospacedDigit())
                        }
                        actionButtons(for: item)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private func actionButtons(for item: PanelItem) -> some View {
        switch item.mode {
        case .start:
            Button {
                onAction(item.block, .start)
            } label: {
                Label("시작", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        case .running, .finish:
            HStack {
                Button { onAction(item.block, .complete) } label: {
                    Label("완료", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                Button { onAction(item.block, .delay) } label: {
                    Label("미룸", systemImage: "arrowshape.turn.up.right")
                }
                .buttonStyle(.bordered)
                Button(role: .destructive) { onAction(item.block, .stop) } label: {
                    Label("중단", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
            }
            .labelStyle(.iconOnly)
        }
    }

    private func panelItem(at now: Date) -> PanelItem? {
        if let block = blocks.first(where: { $0.executionState == .inProgress }) {
            return PanelItem(block: block, mode: block.endAt <= now ? .finish : .running)
        }
        if let block = blocks.first(where: { $0.executionState == .planned && $0.endAt <= now }) {
            return PanelItem(block: block, mode: .finish)
        }
        if let block = blocks.first(where: { $0.executionState == .planned && $0.startAt <= now && now < $0.endAt }) {
            return PanelItem(block: block, mode: .start)
        }
        return nil
    }

    private func remainingText(block: WorkBlock, now: Date) -> String {
        let remaining = max(0, Int(block.endAt.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d 남음", remaining / 3600, (remaining % 3600) / 60, remaining % 60)
    }
}

private struct PanelItem {
    enum Mode { case start, running, finish }
    let block: WorkBlock
    let mode: Mode
    var title: String {
        switch mode {
        case .start: return "시작할 시간입니다"
        case .running: return "진행 중"
        case .finish: return "상태를 선택해 주세요"
        }
    }
    var icon: String {
        switch mode {
        case .start: return "play.circle"
        case .running: return "timer"
        case .finish: return "checklist"
        }
    }
}
