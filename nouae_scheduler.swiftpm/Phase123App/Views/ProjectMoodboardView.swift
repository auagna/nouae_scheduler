import SwiftUI

struct ProjectMoodboardView: View {
    let items: [ProjectBoardItem]

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                ProjectBoardItemCard(item: item)
            }
        }
    }
}
