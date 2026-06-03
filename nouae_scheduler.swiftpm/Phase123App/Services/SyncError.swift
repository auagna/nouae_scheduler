import Foundation

enum SyncError: LocalizedError {
    case permissionDenied
    case reminderPermissionDenied
    case calendarCreationFailed
    case calendarNotFound
    case reminderCalendarNotFound
    case sourceNotFound
    case invalidTimeRange
    case duplicateProjectTitle

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "캘린더 전체 접근 권한이 필요합니다. iPad 설정에서 nou ae의 캘린더 접근을 허용해 주세요."
        case .reminderPermissionDenied:
            return "미리알림 전체 접근 권한이 필요합니다. iPad 설정에서 nou ae의 미리알림 접근을 허용해 주세요."
        case .calendarCreationFailed:
            return "Apple Calendar를 생성하지 못했습니다."
        case .calendarNotFound:
            return "연결된 Apple Calendar를 찾지 못했습니다. 프로젝트 연결 상태를 확인해 주세요."
        case .reminderCalendarNotFound:
            return "새 미리알림을 저장할 기본 목록을 찾지 못했습니다."
        case .sourceNotFound:
            return "새 캘린더를 저장할 계정을 찾지 못했습니다."
        case .invalidTimeRange:
            return "WorkBlock 종료 시간은 시작 시간보다 늦어야 합니다."
        case .duplicateProjectTitle:
            return "같은 이름의 활성 Project가 이미 있습니다. Project는 Apple Calendar와 1:1로 연결됩니다."
        }
    }
}
