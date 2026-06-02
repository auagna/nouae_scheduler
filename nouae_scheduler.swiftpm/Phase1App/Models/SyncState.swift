import Foundation

enum SyncState: String, CaseIterable, Codable, Identifiable {
    case local
    case pending
    case syncing
    case synced
    case failed

    var id: String { rawValue }

    var title: String { rawValue.capitalized }
}
