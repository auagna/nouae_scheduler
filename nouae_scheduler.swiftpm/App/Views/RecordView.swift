import SwiftUI

struct RecordView: View {
    var body: some View {
        ContentUnavailableView(
            "Record",
            systemImage: "square.and.pencil",
            description: Text("다음 단계에서 하루 기록, 작업 기록, 컨디션 기록을 연결합니다.")
        )
        .navigationTitle("Record")
    }
}
