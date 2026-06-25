import SwiftData
import SwiftUI

@main
@MainActor
struct NouAEApp: App {
    private let container: ModelContainer
    private let launchWarning: String?
    @StateObject private var stores: AppStores
    @StateObject private var services: AppServices
    @StateObject private var navigationRouter = AppNavigationRouter.shared

    init() {
        let resolvedContainer: ModelContainer
        let warning: String?

        do {
            resolvedContainer = try AppModelContainer.make()
            warning = nil
        } catch {
            do {
                resolvedContainer = try AppModelContainer.makeInMemory()
                warning = "SwiftData 저장소를 열 수 없어 임시 모드로 실행 중입니다. 기존 데이터는 보호되지만, 이번 실행에서 만든 데이터는 저장되지 않을 수 있습니다."
            } catch {
                fatalError("Failed to create SwiftData container: \(error)")
            }
        }

        let stores = AppStores(context: resolvedContainer.mainContext)
        let services = AppServices(context: resolvedContainer.mainContext, stores: stores)
        self.container = resolvedContainer
        self.launchWarning = warning
        _stores = StateObject(wrappedValue: stores)
        _services = StateObject(wrappedValue: services)
        IntentServiceContainer.shared.configure(container: resolvedContainer, stores: stores, services: services)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stores)
                .environmentObject(services)
                .environmentObject(navigationRouter)
                .safeAreaInset(edge: .top) {
                    if let launchWarning {
                        Text(launchWarning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial)
                    }
                }
        }
        .modelContainer(container)
    }
}
