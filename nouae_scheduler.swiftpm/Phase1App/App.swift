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
            _stores = StateObject(wrappedValue: AppStores(modelContext: container.mainContext))
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stores)
        }
        .modelContainer(modelContainer)
    }
}
