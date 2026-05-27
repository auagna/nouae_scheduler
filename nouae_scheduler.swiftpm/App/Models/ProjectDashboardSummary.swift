import Foundation

struct ProjectDashboardSummary: Equatable {
    let projectId: UUID
    let totalBlocks: Int
    let totalMinutes: Int
    let todayMinutes: Int
    let weekMinutes: Int
    let lastWorkedAt: Date?
}
