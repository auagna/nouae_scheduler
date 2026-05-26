import SwiftUI

enum ScheduleCategory: String, CaseIterable, Identifiable {
    case work = "작업"
    case company = "회사"
    case personal = "개인"
    case social = "소셜"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .work:
            return .blue
        case .company:
            return .purple
        case .personal:
            return .green
        case .social:
            return .orange
        }
    }

    var symbolName: String {
        switch self {
        case .work:
            return "briefcase"
        case .company:
            return "building.2"
        case .personal:
            return "person"
        case .social:
            return "person.2"
        }
    }
}
