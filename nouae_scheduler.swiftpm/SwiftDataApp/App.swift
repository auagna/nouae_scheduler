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
            let appStores = AppStores(modelContext: container.mainContext)
            modelContainer = container
            _stores = StateObject(wrappedValue: appStores)
            _services = StateObject(
                wrappedValue: AppServices(
                    modelContext: container.mainContext,
                    stores: appStores
                )
            )
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MVPContentView()
                .environmentObject(stores)
                .environmentObject(services)
        }
        .modelContainer(modelContainer)
    }
}
