import SwiftUI

struct CalendarPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Calendar",
                systemImage: "calendar",
                description: Text("Apple Calendar 연동과 Day / Week / Month 보기는 Phase 2 이후에 구현합니다.")
            )
            .navigationTitle("Calendar")
        }
    }
}
