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
                    Toggle(isOn: $isDrawingMode) {
                        Image(systemName: "pencil.tip")
                    }
                    .toggleStyle(.button)
                    .accessibilityLabel("Drawing Mode")
                }

                StatusBadge(syncTone == .green ? "Synced" : "Attention", tone: syncTone, symbolName: "calendar")
            }
        }
    }
}
