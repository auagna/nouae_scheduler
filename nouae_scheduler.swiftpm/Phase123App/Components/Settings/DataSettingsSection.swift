import SwiftUI

struct DataSettingsSection: View {
    let onExport: () -> Void
    let onRemoveSamples: () -> Void

    var body: some View {
        AppPanel(title: "Data", subtitle: "데이터는 사용자의 것입니다. 내보내기와 백업은 단계적으로 확장합니다.") {
            Button {
                onExport()
            } label: {
                Label("Export placeholder", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                onRemoveSamples()
            } label: {
                Label("샘플 데이터 제거", systemImage: "trash")
            }
            .buttonStyle(.bordered)

            Text("iCloud Drive 자동 백업과 파일 import는 이후 단계에서 연결합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
