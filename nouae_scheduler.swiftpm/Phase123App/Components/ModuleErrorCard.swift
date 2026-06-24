import SwiftUI

struct ModuleErrorCard: View {
    let moduleName: String
    let error: ModuleError
    var onDisable: (() -> Void)?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(moduleName)
                            .font(.subheadline.weight(.semibold))
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                if let onDisable {
                    Button("Disable Module", role: .destructive, action: onDisable)
                        .buttonStyle(.bordered)
                        .font(.caption.weight(.semibold))
                }
            }
        }
    }
}
