import Foundation
import SwiftUI

struct CalendarBoard: View {
    let date: Date
    let blocks: [WorkBlock]
    let projectColor: (UUID?) -> String?
    let onDropTask: (UUID, Int) -> Void
    let onChangeTime: (WorkBlock, Date, Date) -> Void
    private let minuteHeight: CGFloat = 1
    private let rulerWidth: CGFloat = 54
    private var boardHeight: CGFloat { CGFloat(24 * 60) * minuteHeight }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.vertical) {
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        ruler
                        ForEach(blocks) { block in
                            WorkBlockCard(block: block, color: Color(calendarHex: projectColor(block.projectId)), minuteHeight: minuteHeight, onChangeTime: onChangeTime)
                                .frame(width: max(180, geometry.size.width - rulerWidth - 14))
                                .offset(x: rulerWidth + 6, y: yOffset(for: block))
                        }
                    }
                    .frame(height: boardHeight)
                    .dropDestination(for: String.self) { ids, location in
                        guard let raw = ids.first, let id = UUID(uuidString: raw) else { return false }
                        let minute = min(max(Int(location.y / minuteHeight), 0), 23 * 60 + 50)
                        onDropTask(id, snapped(minute))
                        return true
                    }
                }
                .frame(height: boardHeight)
            }
            .onAppear { reader.scrollTo("hour-8", anchor: .top) }
        }
    }

    private var ruler: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0...24, id: \.self) { hour in
                HStack(spacing: 6) {
                    Text(String(format: "%02d:00", hour)).font(.caption2).foregroundStyle(.secondary).frame(width: 45, alignment: .trailing)
                    Rectangle().fill(.quaternary).frame(height: 1)
                }
                .offset(y: CGFloat(hour * 60) * minuteHeight)
                .id("hour-\(hour)")
            }
        }
    }

    private func yOffset(for block: WorkBlock) -> CGFloat {
        let start = Calendar.current.startOfDay(for: date)
        return CGFloat(Calendar.current.dateComponents([.minute], from: start, to: block.startAt).minute ?? 0) * minuteHeight
    }
    private func snapped(_ minute: Int) -> Int { Int((Double(minute) / 10).rounded()) * 10 }
}

struct WorkBlockCard: View {
    let block: WorkBlock
    let color: Color
    let minuteHeight: CGFloat
    let onChangeTime: (WorkBlock, Date, Date) -> Void
    @GestureState private var moveOffset: CGFloat = 0
    @GestureState private var topOffset: CGFloat = 0
    @GestureState private var bottomOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.2))
            RoundedRectangle(cornerRadius: 7).stroke(color.opacity(0.7), lineWidth: 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(block.title).font(.caption.weight(.semibold)).lineLimit(2)
                Text(timeText).font(.caption2).foregroundStyle(.secondary)
                SyncStatusBadge(state: block.syncState)
            }.padding(.horizontal, 8).padding(.vertical, 7)
            topHandle
            bottomHandle
        }
        .frame(height: liveHeight)
        .offset(y: moveOffset + topOffset)
        .contentShape(Rectangle())
        .gesture(moveGesture)
        .animation(.snappy(duration: 0.18), value: moveOffset)
        .animation(.snappy(duration: 0.18), value: liveHeight)
    }

    private var topHandle: some View { Capsule().fill(color).frame(width: 34, height: 5).frame(maxWidth: .infinity).padding(.vertical, 5).frame(maxHeight: .infinity, alignment: .top).contentShape(Rectangle()).highPriorityGesture(topResizeGesture) }
    private var bottomHandle: some View { Capsule().fill(color).frame(width: 34, height: 5).frame(maxWidth: .infinity).padding(.vertical, 5).frame(maxHeight: .infinity, alignment: .bottom).contentShape(Rectangle()).highPriorityGesture(bottomResizeGesture) }
    private var duration: CGFloat { CGFloat(max(block.durationMinutes, 10)) * minuteHeight }
    private var liveHeight: CGFloat { max(28, duration + bottomOffset - topOffset) }
    private var timeText: String { block.startAt.formatted(date: .omitted, time: .shortened) + " - " + block.endAt.formatted(date: .omitted, time: .shortened) }
    private var moveGesture: some Gesture { DragGesture(minimumDistance: 4).updating($moveOffset) { value, state, _ in state = value.translation.height }.onEnded { move(by: snappedMinutes($0.translation.height)) } }
    private var topResizeGesture: some Gesture { DragGesture(minimumDistance: 2).updating($topOffset) { value, state, _ in state = value.translation.height }.onEnded { value in let start = Calendar.current.date(byAdding: .minute, value: snappedMinutes(value.translation.height), to: block.startAt) ?? block.startAt; onChangeTime(block, start, block.endAt) } }
    private var bottomResizeGesture: some Gesture { DragGesture(minimumDistance: 2).updating($bottomOffset) { value, state, _ in state = value.translation.height }.onEnded { value in let end = Calendar.current.date(byAdding: .minute, value: snappedMinutes(value.translation.height), to: block.endAt) ?? block.endAt; onChangeTime(block, block.startAt, end) } }
    private func move(by delta: Int) { guard delta != 0 else { return }; let calendar = Calendar.current; onChangeTime(block, calendar.date(byAdding: .minute, value: delta, to: block.startAt) ?? block.startAt, calendar.date(byAdding: .minute, value: delta, to: block.endAt) ?? block.endAt) }
    private func snappedMinutes(_ height: CGFloat) -> Int { Int((height / minuteHeight / 10).rounded()) * 10 }
}
