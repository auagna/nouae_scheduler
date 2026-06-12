import SwiftUI

struct ProjectBoardItemCard: View {
    let item: ProjectBoardItem

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: item.itemType.symbolName)
                        .foregroundStyle(itemColor)
                    Text(item.itemType.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !item.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                if !item.content.isEmpty {
                    Text(item.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }

                if let colorHex = item.colorHex, !colorHex.isEmpty {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(calendarHex: colorHex))
                        .frame(height: 18)
                }
            }
        }
    }

    private var itemColor: Color {
        Color(calendarHex: item.colorHex)
    }
}
