import SwiftUI

struct ProjectVisionBoardView: View {
    let project: Project
    let items: [ProjectBoardItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vision Sentence")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(project.goal.isEmpty ? "이 프로젝트가 어떤 방향으로 움직이는지 한 문장으로 남겨보세요." : project.goal)
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ProjectMoodboardView(items: items)
        }
    }
}
