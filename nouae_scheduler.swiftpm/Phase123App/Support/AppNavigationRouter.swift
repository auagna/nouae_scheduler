import Combine
import Foundation

enum AppTab: Hashable {
    case dashboard
    case calendar
    case projects
    case plan
    case log
}

@MainActor
final class AppNavigationRouter: ObservableObject {
    static let shared = AppNavigationRouter()

    @Published var selectedTab: AppTab = .dashboard
    @Published var pendingProjectId: UUID?
    @Published var pendingPlanDate: Date?
    @Published var pendingCalendarDate: Date?
    @Published var pendingLogProjectId: UUID?

    private init() {}

    func openProject(id: UUID) {
        pendingProjectId = id
        selectedTab = .projects
    }

    func openPlan(date: Date?, projectId: UUID?) {
        pendingPlanDate = date
        selectedTab = .plan
    }

    func openCalendar(date: Date?) {
        pendingCalendarDate = date
        selectedTab = .calendar
    }

    func openLog(projectId: UUID?, quickMode: Bool) {
        pendingLogProjectId = projectId
        selectedTab = .log
    }
}
