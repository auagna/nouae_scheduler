import Foundation

enum SyncError: LocalizedError {
    case permissionDenied, calendarCreationFailed, sourceNotFound
    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "캘린더 전체 접근 권한이 필요합니다. iPad 설정에서 nou ae의 캘린더 접근을 허용해 주세요."
        case .calendarCreationFailed: return "Apple Calendar를 생성하지 못했습니다."
        case .sourceNotFound: return "새 캘린더를 저장할 계정을 찾지 못했습니다."
        }
    }
}
