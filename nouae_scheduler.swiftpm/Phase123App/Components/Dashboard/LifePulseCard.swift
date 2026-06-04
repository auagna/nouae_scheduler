import SwiftUI

struct LifePulseCard: View {
    let value: Int

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Life Pulse")
                            .font(.headline)
                        Text("운영 상태 신호")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(value)")
                        .font(.title.bold())
                        .monospacedDigit()
                }

                ProgressView(value: Double(value), total: 100)
                    .tint(.blue)

                HStack {
                    Label("Energy", systemImage: "bolt.fill")
                    Spacer()
                    Label("Focus", systemImage: "scope")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
