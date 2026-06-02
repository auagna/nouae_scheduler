import SwiftUI

struct SyncStatusBadge: View {
    let state: SyncState
    var body: some View { Label(state.title, systemImage: icon).font(.caption2).foregroundStyle(color) }
    private var icon: String { switch state { case .local: return "iphone"; case .pending: return "clock"; case .syncing: return "arrow.triangle.2.circlepath"; case .synced: return "checkmark.circle"; case .failed: return "exclamationmark.triangle" } }
    private var color: Color { switch state { case .synced: return .green; case .failed: return .red; case .pending, .syncing: return .orange; case .local: return .secondary } }
}
