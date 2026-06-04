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
