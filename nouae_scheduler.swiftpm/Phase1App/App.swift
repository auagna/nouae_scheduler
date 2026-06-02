import SwiftData
import SwiftUI

@main
@MainActor
struct NouAEApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var stores: AppStores
    @StateObject private var services: AppServices

    init() {
        do {
            let container = try AppModelContainer.make()
            modelContainer = container
            _stores = StateObject(wrappedValue: AppStores(modelContext: container.mainContext))
            _services = StateObject(wrappedValue: AppServices())
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
        .modelContainer(modelContainer)
    }
}
