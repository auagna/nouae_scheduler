import Foundation

enum SyncError: LocalizedError {
    case permissionDenied
    case calendarNotFound
    case calendarCreationFailed
    case sourceNotFound
    case saveFailed
    case unknown(Error?)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "캘린더 전체 접근 권한이 필요합니다. iPad 설정에서 nou ae의 캘린더 접근을 허용해 주세요."
        case .calendarNotFound:
            return "연결된 Apple Calendar를 찾지 못했습니다."
        case .calendarCreationFailed:
            return "Apple Calendar를 생성하지 못했습니다. 캘린더 계정 상태를 확인해 주세요."
        case .sourceNotFound:
            return "새 캘린더를 저장할 iCloud 또는 기본 Calendar 계정을 찾지 못했습니다."
        case .saveFailed:
            return "프로젝트 동기화 정보를 저장하지 못했습니다."
        case .unknown(let error):
            return error?.localizedDescription ?? "알 수 없는 캘린더 동기화 오류가 발생했습니다."
        }
    }
}
