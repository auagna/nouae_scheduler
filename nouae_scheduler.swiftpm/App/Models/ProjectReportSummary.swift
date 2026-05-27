import Foundation

struct ProjectReportSummary: Equatable {
    let projectId: UUID
    let generatedAt: Date
    let headline: String
    let workMinutes: Int
    let rawTaskCount: Int
    let logCount: Int
    let activeAdjustment: String?
}
