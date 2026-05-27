import SwiftUI

struct ContentView: View {
    @StateObject private var eventKitManager = EventKitManager()

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(eventKitManager: eventKitManager)
            }
            .tabItem {
                Label("Dashboard", systemImage: "rectangle.grid.2x2")
            }

            NavigationStack {
                TimeView(eventKitManager: eventKitManager)
            }
            .tabItem {
                Label("Time", systemImage: "clock")
            }

            NavigationStack {
                CalendarView(eventKitManager: eventKitManager)
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }

            NavigationStack {
                ProjectsView()
            }
            .tabItem {
                Label("Projects", systemImage: "folder")
            }

            NavigationStack {
                RecordView()
            }
            .tabItem {
                Label("Record", systemImage: "square.and.pencil")
            }

            NavigationStack {
                SettingsView(eventKitManager: eventKitManager)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
