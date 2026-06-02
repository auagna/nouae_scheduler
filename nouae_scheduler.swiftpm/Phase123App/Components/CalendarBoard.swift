import Foundation
import SwiftUI

struct CalendarBoard: View {
    let date: Date
    let blocks: [WorkBlock]
    let projects: [Project]
    let onDropTask: (UUID, Date) -> Void
    let onChangeTime: (WorkBlock, Date, Date) -> Void
    let onAction: (WorkBlock, WorkBlockAction) -> Void

    private let pointsPerMinute: CGFloat = 1.1
    private let rulerWidth: CGFloat = 54
    private var boardHeight: CGFloat { CGFloat(24 * 60) * pointsPerMinute }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.vertical) {
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        timeGrid(width: geometry.size.width)
                        ForEach(blocks) { block in
                            WorkBlockCard(
                                block: block,
                                color: color(for: block),
                                pointsPerMinute: pointsPerMinute,
                                onChangeTime: onChangeTime,
                                onAction: onAction
                            )
                            .frame(width: max(180, geometry.size.width - rulerWidth - 12))
                            .offset(x: rulerWidth + 6, y: yOffset(for: block))
                        }
                    }
                    .frame(width: geometry.size.width, height: boardHeight, alignment: .topLeading)
                    .dropDestination(for: String.self) { identifiers, location in
                        guard let value = identifiers.first,
                              let id = UUID(uuidString: value) else { return false }
                        let minute = DateSnapper.clampMinute(Int(location.y / pointsPerMinute))
                        onDropTask(id, DateSnapper.date(on: date, minuteOfDay: minute))
                        return true
                    }
                }
                .frame(height: boardHeight)
            }
            .onAppear {
                DispatchQueue.main.async { reader.scrollTo(8, anchor: .top) }
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func timeGrid(width: CGFloat) -> some View {
        ForEach(0..<25, id: \.self) { hour in
            HStack(spacing: 5) {
                Text(hour < 24 ? String(format: "%02d:00", hour) : "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: rulerWidth - 5, alignment: .trailing)
                Rectangle()
                    .fill(Color.secondary.opacity(hour % 2 == 0 ? 0.26 : 0.16))
                    .frame(width: max(0, width - rulerWidth), height: 0.5)
            }
            .offset(y: CGFloat(hour * 60) * pointsPerMinute)
            .id(hour)
        }
    }

    private func yOffset(for block: WorkBlock) -> CGFloat {
        CGFloat(DateSnapper.minuteOfDay(for: block.startAt)) * pointsPerMinute
    }

    private func color(for block: WorkBlock) -> Color {
        let project = projects.first { $0.id == block.projectId }
        return Color(calendarHex: project?.calendarColorHex)
    }
}
