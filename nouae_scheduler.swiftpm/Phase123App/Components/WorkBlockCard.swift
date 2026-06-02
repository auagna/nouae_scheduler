import Foundation
import SwiftUI

struct WorkBlockCard: View {
    let block: WorkBlock
    let color: Color
    let pointsPerMinute: CGFloat
    let onChangeTime: (WorkBlock, Date, Date) -> Void
    let onAction: (WorkBlock, WorkBlockAction) -> Void

    @GestureState private var moveTranslation: CGFloat = 0
    @GestureState private var topTranslation: CGFloat = 0
    @GestureState private var bottomTranslation: CGFloat = 0

    private var durationMinutes: CGFloat {
        max(CGFloat(DateSnapper.minimumDurationMinutes), CGFloat(block.endAt.timeIntervalSince(block.startAt) / 60))
    }

    private var baseHeight: CGFloat { max(44, durationMinutes * pointsPerMinute) }
    private var liveHeight: CGFloat { max(44, baseHeight - topTranslation + bottomTranslation) }
    private var liveYOffset: CGFloat { moveTranslation + topTranslation }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 7)
                .fill(color.opacity(0.2))
            RoundedRectangle(cornerRadius: 7)
                .stroke(color.opacity(0.7), lineWidth: 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(block.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(timeRange)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(block.executionState.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                SyncStatusBadge(state: block.syncState)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            VStack(spacing: 0) {
                resizeHandle
                    .highPriorityGesture(topResizeGesture)
                Spacer(minLength: 0)
                resizeHandle
                    .highPriorityGesture(bottomResizeGesture)
            }
        }
        .frame(height: liveHeight)
        .offset(y: liveYOffset)
        .gesture(moveGesture)
        .contextMenu { actionMenu }
        .animation(.easeInOut(duration: 0.14), value: liveHeight)
        .animation(.easeInOut(duration: 0.14), value: liveYOffset)
        .accessibilityLabel("\(block.title), \(timeRange), \(block.executionState.title)")
    }

    @ViewBuilder
    private var actionMenu: some View {
        if block.executionState == .planned {
            Button { onAction(block, .start) } label: { Label("시작", systemImage: "play.fill") }
        }
        if block.executionState == .planned || block.executionState == .inProgress {
            Button { onAction(block, .complete) } label: { Label("완료", systemImage: "checkmark") }
            Button { onAction(block, .delay) } label: { Label("미룸", systemImage: "arrowshape.turn.up.right") }
            Button(role: .destructive) { onAction(block, .stop) } label: { Label("중단", systemImage: "stop.fill") }
        }
    }

    private var resizeHandle: some View {
        Capsule()
            .fill(color)
            .frame(width: 34, height: 4)
            .frame(maxWidth: .infinity, minHeight: 14)
            .contentShape(Rectangle())
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .updating($moveTranslation) { value, state, _ in
                state = snappedPoints(value.translation.height)
            }
            .onEnded { value in
                let delta = DateSnapper.snappedMinuteDelta(for: value.translation.height, pointsPerMinute: pointsPerMinute)
                onChangeTime(
                    block,
                    Calendar.current.date(byAdding: .minute, value: delta, to: block.startAt) ?? block.startAt,
                    Calendar.current.date(byAdding: .minute, value: delta, to: block.endAt) ?? block.endAt
                )
            }
    }

    private var topResizeGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .updating($topTranslation) { value, state, _ in
                state = snappedPoints(value.translation.height)
            }
            .onEnded { value in
                let delta = DateSnapper.snappedMinuteDelta(for: value.translation.height, pointsPerMinute: pointsPerMinute)
                let start = Calendar.current.date(byAdding: .minute, value: delta, to: block.startAt) ?? block.startAt
                guard start < block.endAt else { return }
                onChangeTime(block, start, block.endAt)
            }
    }

    private var bottomResizeGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .updating($bottomTranslation) { value, state, _ in
                state = snappedPoints(value.translation.height)
            }
            .onEnded { value in
                let delta = DateSnapper.snappedMinuteDelta(for: value.translation.height, pointsPerMinute: pointsPerMinute)
                let end = Calendar.current.date(byAdding: .minute, value: delta, to: block.endAt) ?? block.endAt
                guard end > block.startAt else { return }
                onChangeTime(block, block.startAt, end)
            }
    }

    private func snappedPoints(_ value: CGFloat) -> CGFloat {
        CGFloat(DateSnapper.snappedMinuteDelta(for: value, pointsPerMinute: pointsPerMinute)) * pointsPerMinute
    }

    private var timeRange: String {
        block.startAt.formatted(date: .omitted, time: .shortened) + " - " + block.endAt.formatted(date: .omitted, time: .shortened)
    }
}
