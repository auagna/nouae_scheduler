import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var navigationRouter: AppNavigationRouter

    var body: some View {
        mainTabs
    }

    private var mainTabs: some View {
        TabView(selection: $navigationRouter.selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "rectangle.grid.2x2") }
                .tag(AppTab.dashboard)
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "folder") }
                .tag(AppTab.projects)
            PlanView()
                .tabItem { Label("Plan", systemImage: "clock") }
                .tag(AppTab.plan)
            LogView()
                .tabItem { Label("Log", systemImage: "square.and.pencil") }
                .tag(AppTab.log)
        }
    }
}