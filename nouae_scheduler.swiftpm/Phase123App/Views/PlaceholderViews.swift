import SwiftUI

struct CalendarPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Calendar", systemImage: "calendar", description: Text("Calendar 흐름 보기는 다음 Phase에서 연결합니다."))
                .navigationTitle("Calendar")
        }
    }
}
