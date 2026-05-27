import SwiftUI

struct TimeBlockView: View {
    let block: TimeBlock
    let pointsPerHour: CGFloat
    let onMove: (Int) -> Void
    let onResizeStart: (Int) -> Void
    let onResizeEnd: (Int) -> Void

    @State private var moveOffset: CGFloat = 0
    @State private var topHandleOffset: CGFloat = 0
    @State private var bottomHandleOffset: CGFloat = 0

    private var pointsPerMinute: CGFloat { pointsPerHour / 60 }

    var body: some View {
        VStack(spacing: 0) {
            handle.gesture(resizeStartGesture)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: block.category.symbolName)
                    Text(block.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(block.syncStatus.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.14), in: Capsule())
                }

                Text("\(timeText(block.startAt)) - \(timeText(block.endAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text(block.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(block.category.color)

                    if let projectTitle = block.projectTitle, !projectTitle.isEmpty {
                        Text(projectTitle)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(block.category.color.opacity(0.12), in: Capsule())
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(moveGesture)

            handle.gesture(resizeEndGesture)
        }
        .background(block.category.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(block.category.color.opacity(block.syncStatus == .failed ? 0.95 : 0.45), lineWidth: block.syncStatus == .failed ? 2 : 1)
        )
        .offset(y: moveOffset + topHandleOffset)
    }

    private var handle: some View {
        Capsule()
            .fill(block.category.color.opacity(0.5))
            .frame(width: 42, height: 5)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in moveOffset = value.translation.height }
            .onEnded { value in
                let minutes = snappedMinutes(from: value.translation.height)
                moveOffset = 0
                if minutes != 0 { onMove(minutes) }
            }
    }

    private var resizeStartGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in topHandleOffset = value.translation.height }
            .onEnded { value in
                let minutes = snappedMinutes(from: value.translation.height)
                topHandleOffset = 0
                if minutes != 0 { onResizeStart(minutes) }
            }
    }

    private var resizeEndGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in bottomHandleOffset = value.translation.height }
            .onEnded { value in
                let minutes = snappedMinutes(from: value.translation.height)
                bottomHandleOffset = 0
                if minutes != 0 { onResizeEnd(minutes) }
            }
    }

    private var statusColor: Color {
        switch block.syncStatus {
        case .local: return .secondary
        case .pending: return .orange
        case .syncing: return .blue
        case .synced: return .green
        case .failed: return .red
        }
    }

    private func snappedMinutes(from points: CGFloat) -> Int {
        let rawMinutes = points / pointsPerMinute
        return Int((rawMinutes / 15).rounded()) * 15
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
