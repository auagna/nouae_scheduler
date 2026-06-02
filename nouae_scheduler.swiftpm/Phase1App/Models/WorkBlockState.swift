import Foundation

enum WorkBlockState: String, CaseIterable, Codable, Identifiable {
    case planned
    case inProgress
    case completed
    case delayed
    case stopped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .delayed: return "Delayed"
        case .stopped: return "Stopped"
        }
    }
}
