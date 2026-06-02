import SwiftData
import SwiftUI

@main
@MainActor
struct NouAEApp: App {
    private let container: ModelContainer
    @StateObject private var stores: AppStores
    @StateObject private var services: AppServices

    init() {
        do {
            let container = try AppModelContainer.make()
            let stores = AppStores(context: container.mainContext)
            self.container = container
            _stores = StateObject(wrappedValue: stores)
            _services = StateObject(wrappedValue: AppServices(context: container.mainContext, stores: stores))
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stores)
                .environmentObject(services)
        }
        .modelContainer(container)
    }
}
