import SwiftUI

struct FlowMatrixPreview: View {
    let relations: [String]

    var body: some View {
        AppPanel(title: "Flow Matrix", subtitle: "Relationships preview") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(relations, id: \.self) { relation in
                        RelationshipMiniCard(title: relation)
                    }
                }
            }
        }
    }
}

private struct RelationshipMiniCard: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.blue.opacity(0.65))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
