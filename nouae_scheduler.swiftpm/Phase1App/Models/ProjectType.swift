import Foundation

enum ProjectType: String, CaseIterable, Codable, Identifiable {
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
