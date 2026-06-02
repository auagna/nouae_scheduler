import SwiftUI

struct ExecutionPanel: View {
    let block: WorkBlock
    let projectTitle: String?
    let onStart: () -> Void
    let onComplete: () -> Void
    let onDelay: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: block.executionState == .inProgress ? "timer" : "bell")
                    .font(.headline)
                Spacer()
                Text(remainingText).font(.caption).foregroundStyle(.secondary)
            }
            Text(block.title).font(.subheadline.weight(.semibold))
            if let projectTitle { Text(projectTitle).font(.caption).foregroundStyle(.secondary) }
            if !block.memo.isEmpty { Text(block.memo).font(.caption).foregroundStyle(.secondary) }
            HStack {
                if block.executionState == .planned { Button("시작", action: onStart).buttonStyle(.borderedProminent) }
                Button("완료", action: onComplete).buttonStyle(.bordered)
                Button("미룸", action: onDelay).buttonStyle(.bordered)
                Button("중단", action: onStop).buttonStyle(.bordered).tint(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private var title: String { block.executionState == .inProgress ? "진행중" : "시작할 시간입니다" }
    private var remainingText: String {
        let minutes = max(Int(block.endAt.timeIntervalSinceNow / 60), 0)
        return "남은 시간 \(minutes)분"
    }
}
