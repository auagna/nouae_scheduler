enum SyncStatus: String, Codable {
    case local
    case pending
    case syncing
    case synced
    case failed

    var label: String {
        switch self {
        case .local:
            return "로컬"
        case .pending:
            return "대기"
        case .syncing:
            return "동기화 중"
        case .synced:
            return "동기화됨"
        case .failed:
            return "실패"
        }
    }
}
