import SwiftUI

struct StatCard: View {
    let title: String
    let value: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(minWidth: 92, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
