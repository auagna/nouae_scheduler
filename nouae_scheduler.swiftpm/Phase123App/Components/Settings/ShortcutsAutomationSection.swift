import SwiftData
import SwiftUI

struct ShortcutsAutomationSection: View {
    let moduleCount: Int
    let onRefresh: () -> Void

    var body: some View {
        AppPanel(
            title: "Shortcuts & Automation",
            subtitle: "Siri, Shortcuts, and safe Module Actions"
        ) {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Button("Refresh", action: onRefresh)
                        .font(.caption.weight(.semibold))
                }

                shortcutRow(symbol: "plus.circle", title: "Capture RawTask", subtitle: "빠르게 Inbox에 작업을 추가합니다.")
                shortcutRow(symbol: "arrow.right.circle", title: "Show Next Action", subtitle: "현재 다음 행동을 확인합니다.")
                shortcutRow(symbol: "repeat.circle", title: "Start Routine", subtitle: "Routine Occurrence와 WorkBlock을 시작합니다.")
                shortcutRow(symbol: "square.and.pencil", title: "Quick Log", subtitle: "짧은 회고 데이터를 저장합니다.")
                shortcutRow(symbol: "folder", title: "Open Project", subtitle: "Project Dashboard로 이동합니다.")

                AppDivider()

                AppListRow(title: "Installed Module Actions", subtitle: "\(moduleCount)개 Module Action이 Shortcuts 후보입니다.") {
                    Image(systemName: "shippingbox")
                        .foregroundStyle(.blue)
                } trailing: {
                    StatusBadge(moduleCount == 0 ? "None" : "\(moduleCount)", tone: moduleCount == 0 ? .neutral : .blue)
                }

                Text("App Intents는 기존 Store와 Sync Manager를 호출하는 adapter layer입니다. Calendar, Reminder, Module 권한 규칙은 우회하지 않습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

#if NOUAE_ENABLE_APP_INTENTS && canImport(AppIntents)
                Text("Shortcuts 앱에서 nou ae Core Actions를 검색할 수 있습니다. 실제 Siri/Shortcuts 노출은 iPad 실기기에서 확인이 필요합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
#else
                Text("Swift Playgrounds 빌드에서는 앱 본체 안정성을 위해 App Intents 컴파일을 비활성화했습니다. TestFlight/Xcode 빌드에서 NOUAE_ENABLE_APP_INTENTS를 켜면 Shortcuts 노출을 다시 활성화할 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
#endif
            }
        }
    }

    private func shortcutRow(symbol: String, title: String, subtitle: String) -> some View {
        AppListRow(title: title, subtitle: subtitle) {
            Image(systemName: symbol)
                .foregroundStyle(.blue)
        } trailing: {
            StatusBadge("Core", tone: .green)
        }
    }
}