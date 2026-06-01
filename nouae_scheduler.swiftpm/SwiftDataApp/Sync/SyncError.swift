import Foundation

enum SyncError: LocalizedError {
    case calendarAccessDenied
    case reminderAccessDenied
    case missingCalendarSource
    case missingProjectCalendar
    case missingReminderCalendar
    case invalidTimeRange
    case message(String)

    var errorDescription: String? {
        switch self {
        case .calendarAccessDenied:
            return "캘린더 접근 권한이 필요합니다. 설정에서 캘린더 전체 접근을 허용해 주세요."
        case .reminderAccessDenied:
            return "미리알림 접근 권한이 필요합니다. 설정에서 미리알림 전체 접근을 허용해 주세요."
        case .missingCalendarSource:
            return "새 프로젝트 캘린더를 만들 수 있는 Apple Calendar 계정을 찾지 못했습니다."
        case .missingProjectCalendar:
            return "프로젝트에 연결된 Apple Calendar를 찾지 못했습니다."
        case .missingReminderCalendar:
            return "새 항목을 저장할 Apple Reminders 목록을 찾지 못했습니다."
        case .invalidTimeRange:
            return "작업 종료 시간은 시작 시간보다 뒤여야 합니다."
        case .message(let message):
            return message
        }
    }
}
