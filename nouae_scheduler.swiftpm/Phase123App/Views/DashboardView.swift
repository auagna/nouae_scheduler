import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var stores: AppStores
    @Query private var projects: [Project]
    @Query private var tasks: [RawTask]
    @Query private var blocks: [WorkBlock]
    @State private var message: String?

    var body: some View {
        NavigationStack { List { Section { Text("nou ae Phase 1 · 2 · 3").font(.headline); Text("프로젝트 운영판의 안정 기준점입니다.").foregroundStyle(.secondary) }; Section("Local Data") { row("Projects", projects.count); row("Inbox", tasks.filter { !$0.isConvertedToBlock }.count); row("Today Work", blocks.filter { Calendar.current.isDateInToday($0.startAt) }.count) }; Section { Button("샘플 데이터 생성") { seed() } }; if let message { Text(message).foregroundStyle(.secondary) } }.navigationTitle("Dashboard") }
    }
    private func row(_ title: String, _ value: Int) -> some View { HStack { Text(title); Spacer(); Text("\(value)").foregroundStyle(.secondary) } }
    private func seed() { do { try SampleDataSeeder.seed(context: context, stores: stores); message = "샘플 데이터를 확인했습니다." } catch { message = error.localizedDescription } }
}
