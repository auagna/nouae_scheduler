import Foundation

enum ProjectStatus: String, CaseIterable, Codable, Identifiable {
    case planning
    case scheduled
    case active
    case completed
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planning: return "Planning"
        case .scheduled: return "Scheduled"
        case .active: return "Active"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
}
