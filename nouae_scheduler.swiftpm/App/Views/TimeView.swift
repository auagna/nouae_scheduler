import SwiftUI

struct TimeView: View {
    @ObservedObject var eventKitManager: EventKitManager
    @StateObject private var store: TimeBlockStore

    private let pointsPerHour: CGFloat = 72
    private let timelineWidthPadding: CGFloat = 58

    init(eventKitManager: EventKitManager) {
        self.eventKitManager = eventKitManager
        _store = StateObject(wrappedValue: TimeBlockStore(eventKitManager: eventKitManager))
    }

    var body: some View {
        VStack(spacing: 0) {
            QuickInputPanel(store: store, eventKitManager: eventKitManager)
                .padding(.vertical, 8)

            if let message = store.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
            }

            ScrollView(.vertical) {
                ZStack(alignment: .topLeading) {
                    TimeRulerView(pointsPerHour: pointsPerHour)

                    ForEach(store.blocks) { block in
                        TimeBlockView(
                            block: block,
                            pointsPerHour: pointsPerHour,
                            onMove: { minutes in
                                store.moveBlock(id: block.id, byMinutes: minutes)
                            },
                            onResizeStart: { minutes in
                                store.resizeBlockStart(id: block.id, byMinutes: minutes)
                            },
                            onResizeEnd: { minutes in
                                store.resizeBlockEnd(id: block.id, byMinutes: minutes)
                            }
                        )
                        .frame(height: blockHeight(for: block))
                        .padding(.trailing, 12)
                        .offset(x: timelineWidthPadding, y: yOffset(for: block))
                    }
                }
                .frame(height: pointsPerHour * 24 + 20)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Time")
        .toolbar {
            Button {
                Task { await store.loadToday() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
        .task {
            await store.loadToday()
        }
    }

    private func yOffset(for block: TimeBlock) -> CGFloat {
        let dayStart = Calendar.current.startOfDay(for: block.startAt)
        let minutes = block.startAt.timeIntervalSince(dayStart) / 60
        return CGFloat(minutes) * pointsPerHour / 60
    }

    private func blockHeight(for block: TimeBlock) -> CGFloat {
        max(44, CGFloat(block.durationMinutes) * pointsPerHour / 60)
    }
}
