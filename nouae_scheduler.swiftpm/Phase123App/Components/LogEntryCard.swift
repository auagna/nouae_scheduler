import SwiftUI

struct LogEntryCard: View {
    let log: ProjectLog
    let projectTitle: String?
    let workBlockTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(projectTitle ?? "프로젝트 없음")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(log.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let workBlockTitle {
                Label(workBlockTitle, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let focusLevel = log.focusLevel {
                Label("집중도 \(focusLevel)/5", systemImage: "scope")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !log.blockerTags.isEmpty {
                Text(log.blockerTags.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !log.content.isEmpty {
                Text(log.content)
                    .font(.callout)
                    .lineLimit(3)
            }
            if !log.nextAdjustment.isEmpty {
                Label(log.nextAdjustment, systemImage: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
