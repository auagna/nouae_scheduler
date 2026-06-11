import SwiftUI

struct PermissionStatusCard: View {
    let title: String
    let explanation: String
    let isGranted: Bool
    let systemImage: String
    let onRequest: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        AppPanel(title: title, subtitle: explanation) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(isGranted ? .green : .orange)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 4) {
                    Text(isGranted ? "허용됨" : "권한 필요")
                        .font(.subheadline.weight(.semibold))
                    Text(isGranted ? "nou ae가 Apple 기본 앱과 연결할 수 있습니다." : "권한이 거부되면 설정 앱에서 다시 허용해야 합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(isGranted ? "Ready" : "Needed", tone: isGranted ? .green : .orange)
            }

            HStack {
                Button("권한 요청", action: onRequest)
                    .buttonStyle(.borderedProminent)
                    .disabled(isGranted)
                Button("설정 열기", action: onOpenSettings)
                    .buttonStyle(.bordered)
            }
        }
    }
}
