import SwiftUI

struct ContentView: View {
    @AppStorage("nouae.onboarding.completed") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            mainTabs
        } else {
            OnboardingView()
        }
    }

    private var mainTabs: some View {
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
    }
}
