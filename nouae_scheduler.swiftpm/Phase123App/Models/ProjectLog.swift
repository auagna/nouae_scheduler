import Foundation
import SwiftData

enum LogType: String, CaseIterable, Identifiable {
    case daily
    case project
    case workBlock
    case mood
    case recovery
    case experiment
    case insight
    case adjustment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "오늘 회고"
        case .project: return "프로젝트 회고"
        case .workBlock: return "작업 회고"
        case .mood: return "상태 기록"
        case .recovery: return "회복 기록"
        case .experiment: return "실험 기록"
        case .insight: return "아이디어 기록"
        case .adjustment: return "다음 조정"
        }
    }
}

@Model
final class ProjectLog {
    @Attribute(.unique) var id: UUID
    var logTypeRawValue: String
    var areaId: UUID?
    var projectId: UUID?
    var workBlockId: UUID?
    var title: String
    var focusLevel: Int?
    var moodTags: [String]
    var blockerTags: [String]
    var blockerNote: String
    var nextAdjustment: String
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        logType: LogType = .daily,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        workBlockId: UUID? = nil,
        title: String = "",
        focusLevel: Int? = nil,
        moodTags: [String] = [],
        blockerTags: [String] = [],
        blockerNote: String = "",
        nextAdjustment: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        logTypeRawValue = logType.rawValue
        self.areaId = areaId
        self.projectId = projectId
        self.workBlockId = workBlockId
        self.title = title
        self.focusLevel = focusLevel
        self.moodTags = moodTags
        self.blockerTags = blockerTags
        self.blockerNote = blockerNote
        self.nextAdjustment = nextAdjustment
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension ProjectLog {
    var logType: LogType {
        get { LogType(rawValue: logTypeRawValue) ?? .daily }
        set { logTypeRawValue = newValue.rawValue }
    }
}
