import SwiftUI

struct ProjectNoteTab: View {
    let type: ProjectNoteType
    let isSelected: Bool

    var body: some View {
        Label(type.title, systemImage: type.symbolName)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.14) : Color(uiColor: .tertiarySystemGroupedBackground), in: Capsule())
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
    }
}
