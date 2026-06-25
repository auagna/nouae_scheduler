import Foundation

enum ProjectType: String, CaseIterable, Identifiable, Codable {
    case study
    case work
    case exercise
    case creative
    case portfolio
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study: return "Study"
        case .work: return "Work"
        case .exercise: return "Exercise"
        case .creative: return "Creative"
        case .portfolio: return "Portfolio"
        case .personal: return "Personal"
        }
    }
}

enum ProjectStatus: String, CaseIterable, Identifiable, Codable {
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

enum WorkBlockState: String, CaseIterable, Identifiable, Codable {
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

enum SyncState: String, CaseIterable, Identifiable, Codable {
    case local
    case pending
    case syncing
    case synced
    case failed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .local: return "Local"
        case .pending: return "Pending"
        case .syncing: return "Syncing"
        case .synced: return "Synced"
        case .failed: return "Failed"
        }
    }
}

enum ProjectSectionType: String, CaseIterable, Identifiable, Codable {
    case goal
    case inbox
    case memo
    case link
    case nextAdjustment
    case observation
    case experiment
    case failure
    case insight
    case synthesis
    case evolution
    case output

    var id: String { rawValue }
}
