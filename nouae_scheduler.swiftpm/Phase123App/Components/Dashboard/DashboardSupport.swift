import Foundation

struct DashboardInsight: Identifiable {
    let id = UUID()
    let type: String
    let title: String
    let message: String
}

struct DashboardMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct DashboardSnapshot {
    var planned: Int
    var inProgress: Int
    var completed: Int
    var delayedToday: Int

    static let empty = DashboardSnapshot(planned: 0, inProgress: 0, completed: 0, delayedToday: 0)
}
