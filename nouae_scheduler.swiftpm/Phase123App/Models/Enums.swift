import Foundation

enum ProjectType: String, CaseIterable, Identifiable {
    case study, work, exercise, creative, portfolio, personal
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum ProjectStatus: String, CaseIterable, Identifiable {
    case planning, scheduled, active, completed, archived
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum WorkBlockState: String, CaseIterable, Identifiable {
    case planned, inProgress, completed, delayed, stopped
    var id: String { rawValue }
    var title: String {
        switch self {
        case .inProgress: return "In Progress"
        default: return rawValue.capitalized
        }
    }
}

enum SyncState: String, CaseIterable, Identifiable {
    case local, pending, syncing, synced, failed
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}
