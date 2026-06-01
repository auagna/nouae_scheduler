import SwiftData
import SwiftUI

@main
@MainActor
struct NouAEApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var stores: AppStores

    init() {
        do {
            let container = try AppModelContainer.make()
            modelContainer = container
            _stores = StateObject(
                wrappedValue: AppStores(modelContext: container.mainContext)
            )
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            FoundationRootView()
                .environmentObject(stores)
        }
        .modelContainer(modelContainer)
    }
}
