import SwiftData
import SwiftUI

struct ProjectNextAdjustmentSection: View {
    let project: Project
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]
    @State private var content = ""

    var body: some View {
        Section("다음 조정") {
            ForEach(adjustments.filter { $0.projectId == project.id }) { item in Text(item.content).foregroundStyle(item.isActive ? Color.primary : Color.secondary) }
            HStack { TextField("새 조정사항", text: $content); Button { add() } label: { Image(systemName: "plus.circle.fill") }.disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }
    }
    private func add() { try? stores.adjustmentStore.createAdjustment(projectId: project.id, content: content); content = "" }
}
