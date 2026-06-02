import SwiftUI

struct MVPContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "rectangle.grid.2x2") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "folder") }
            PlanView()
                .tabItem { Label("Plan", systemImage: "clock") }
            LogView()
                .tabItem { Label("Log", systemImage: "square.and.pencil") }
        }
        .modifier(SyncRefreshModifier())
    }
}
