import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case calendarPermission
    case reminderPermission
    case blockSetup
    case firstArea
    case firstProject
    case firstRawTask
    case firstWorkBlock
    case firstLog

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "nou ae"
        case .calendarPermission: return "Calendar Sync"
        case .reminderPermission: return "Reminder Sync"
        case .blockSetup: return "BLOCK Setup"
        case .firstArea: return "First Area"
        case .firstProject: return "First Project"
        case .firstRawTask: return "First RawTask"
        case .firstWorkBlock: return "First WorkBlock"
        case .firstLog: return "First Log"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Personal Operating System"
        case .calendarPermission:
            return "WorkBlock을 Apple Calendar와 연결합니다."
        case .reminderPermission:
            return "RawTask Inbox를 Apple Reminders와 연결합니다."
        case .blockSetup:
            return "Project가 정해지지 않은 항목의 임시 저장소입니다."
        case .firstArea:
            return "Area는 삶의 영역이고 Apple Calendar + Reminder List입니다."
        case .firstProject:
            return "Project는 Area 안의 작업세계입니다."
        case .firstRawTask:
            return "RawTask는 빠르게 붙잡은 생각이나 할 일입니다."
        case .firstWorkBlock:
            return "WorkBlock은 시간 위에 배치된 실행 블록입니다."
        case .firstLog:
            return "Log는 짧은 회고와 다음 조정을 남기는 reflection data입니다."
        }
    }
}
