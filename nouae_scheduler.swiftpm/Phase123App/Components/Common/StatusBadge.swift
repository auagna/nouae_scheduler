import SwiftUI

struct StatusBadge: View {
    enum Tone {
        case neutral
        case blue
        case green
        case orange
        case red
        case purple

        var color: Color {
            switch self {
            case .neutral: return .secondary
            case .blue: return .blue
            case .green: return .green
            case .orange: return .orange
            case .red: return .red
            case .purple: return .purple
            }
        }
    }

    let text: String
    let tone: Tone
    let symbolName: String?

    init(_ text: String, tone: Tone = .neutral, symbolName: String? = nil) {
        self.text = text
        self.tone = tone
        self.symbolName = symbolName
    }

    var body: some View {
        HStack(spacing: 4) {
            if let symbolName {
                Image(systemName: symbolName)
                    .font(.caption2.weight(.semibold))
            }
            Text(text)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(tone.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tone.color.opacity(0.12), in: Capsule())
    }
}
