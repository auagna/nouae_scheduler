import SwiftUI

struct TimeRulerView: View {
    let pointsPerHour: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0...24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)

                    Rectangle()
                        .fill(Color.secondary.opacity(hour == 24 ? 0.25 : 0.16))
                        .frame(height: 1)
                        .padding(.top, 7)
                }
                .frame(height: hour == 24 ? 16 : pointsPerHour, alignment: .top)
            }
        }
    }
}
