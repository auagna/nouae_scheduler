import SwiftUI

struct AreaNotebookTab: View {
    let area: ProjectArea
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(calendarHex: area.calendarColorHex))
                .frame(width: 9, height: 9)
            Text(area.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color(uiColor: .tertiarySystemGroupedBackground), in: Capsule())
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
    }
}
