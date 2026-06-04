import SwiftUI

struct MissionControlHeader: View {
    let summary: String
    let syncText: String
    let syncTone: StatusBadge.Tone

    var body: some View {
        AppPageHeader(title: "Mission Control", subtitle: summary) {
            VStack(alignment: .trailing, spacing: 7) {
                StatusBadge(syncText, tone: syncTone, symbolName: syncSymbolName)
                Text(Date(), style: .date)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var syncSymbolName: String {
        switch syncTone {
        case .green: return "checkmark.icloud"
        case .orange, .red: return "exclamationmark.icloud"
        default: return "icloud"
        }
    }
}
