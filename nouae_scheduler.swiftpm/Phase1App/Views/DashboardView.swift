import SwiftData
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var stores: AppStores
    @Query private var projects: [Project]
    @Query private var tasks: [RawTask]
    @Query private var blocks: [WorkBlock]
    @Query private var logs: [ProjectLog]
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("nou ae Phase 1")
                        .font(.headline)
                    Text("SwiftData 기반 구조와 탭 흐름을 확인합니다.")
                        .foregroundStyle(.secondary)
                }
                Section("Local Data") {
                    metric("Projects", projects.count, "folder")
                    metric("RawTask Inbox", tasks.filter { !$0.isConvertedToBlock }.count, "tray")
                    metric("Today WorkBlocks", blocks.filter { Calendar.current.isDateInToday($0.startAt) }.count, "clock")
                    metric("Logs", logs.count, "square.and.pencil")
                }
                Section {
                    Button("샘플 데이터 생성") { seed() }
                } footer: {
                    Text("중복 생성을 방지합니다. 데이터가 이미 있으면 현재 값을 유지합니다.")
                }
                if let message { Section { Text(message).foregroundStyle(.secondary) } }
            }
            .navigationTitle("Dashboard")
        }
    }

    private func metric(_ title: String, _ value: Int, _ icon: String) -> some View {
        Label { HStack { Text(title); Spacer(); Text("\(value)").foregroundStyle(.secondary) } } icon: { Image(systemName: icon) }
    }

    private func seed() {
        do { try SampleDataSeeder.seed(using: stores); message = "샘플 데이터를 확인했습니다." }
        catch { message = error.localizedDescription }
    }
}
