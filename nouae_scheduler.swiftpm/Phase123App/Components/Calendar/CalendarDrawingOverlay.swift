import SwiftUI

struct CalendarDrawingOverlay: View {
    @Binding var data: Data

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())

            VStack(spacing: 8) {
                Image(systemName: "pencil.tip")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Drawing Mode")
                    .font(.headline)
                Text("Apple Pencil canvas is disabled in this stability build.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
