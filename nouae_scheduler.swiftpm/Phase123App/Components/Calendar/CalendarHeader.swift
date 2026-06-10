import SwiftUI

struct CalendarHeader: View {
    let subtitle: String
    let syncTone: StatusBadge.Tone
    @Binding var isDrawingMode: Bool
    let showsDrawingToggle: Bool
    let onToday: () -> Void
    let onFilter: () -> Void

    var body: some View {
        AppPageHeader(title: "Calendar", subtitle: subtitle) {
            HStack(spacing: 8) {
                Button("Today", action: onToday)
                    .buttonStyle(.bordered)

                Button(action: onFilter) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Calendar Filter")

                if showsDrawingToggle {
                    Button {
                        isDrawingMode.toggle()
                    } label: {
                        Image(systemName: "pencil.tip")
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isDrawingMode ? .blue : .gray)
                    .accessibilityLabel("Drawing Mode")
                }

                StatusBadge(syncStatusText, tone: syncTone, symbolName: syncStatusSymbolName)
            }
        }
    }

    private var syncStatusText: String {
        switch syncTone {
        case .green:
            return "Synced"
        case .orange, .red:
            return "Attention"
        default:
            return "Calendar"
        }
    }

    private var syncStatusSymbolName: String {
        switch syncTone {
        case .green:
            return "checkmark.circle"
        case .orange, .red:
            return "exclamationmark.circle"
        default:
            return "calendar"
        }
    }
}
