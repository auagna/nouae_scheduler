import SwiftUI

struct ProjectsView: View {
    var body: some View {
        ContentUnavailableView(
            "Projects",
            systemImage: "folder",
            description: Text("다음 단계에서 프로젝트별 일정, 할 일, 기록 연결을 구현합니다.")
        )
        .navigationTitle("Projects")
    }
}
