import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Dashboard", systemImage: "rectangle.grid.2x2") }
            CalendarPlaceholderView().tabItem { Label("Calendar", systemImage: "calendar") }
            ProjectsView().tabItem { Label("Projects", systemImage: "folder") }
            PlanView().tabItem { Label("Plan", systemImage: "clock") }
            LogView().tabItem { Label("Log", systemImage: "square.and.pencil") }
        }
    }
}
