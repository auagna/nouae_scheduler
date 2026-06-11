import Foundation
import SwiftData

enum ProjectNoteType: String, CaseIterable, Identifiable {
    case workJournal
    case diary
    case planner
    case reflection
    case studio
    case experiment
    case sketch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workJournal: return "업무일지"
        case .diary: return "일기"
        case .planner: return "플래너"
        case .reflection: return "회고"
        case .studio: return "작업실 노트"
        case .experiment: return "실험 노트"
        case .sketch: return "스케치 노트"
        }
    }

    var symbolName: String {
        switch self {
        case .workJournal: return "doc.text"
        case .diary: return "book.closed"
        case .planner: return "calendar.badge.clock"
        case .reflection: return "arrow.triangle.2.circlepath"
        case .studio: return "paintpalette"
        case .experiment: return "flask"
        case .sketch: return "pencil.and.outline"
        }
    }
}

@Model
final class ProjectNote {
    @Attribute(.unique) var id: UUID
    var areaId: UUID?
    var projectId: UUID?
    var noteTypeRawValue: String
    var title: String
    var content: String
    var drawingData: Data?
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        noteType: ProjectNoteType = .planner,
        title: String = "",
        content: String = "",
        drawingData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.areaId = areaId
        self.projectId = projectId
        noteTypeRawValue = noteType.rawValue
        self.title = title.isEmpty ? noteType.title : title
        self.content = content
        self.drawingData = drawingData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

extension ProjectNote {
    var noteType: ProjectNoteType {
        get { ProjectNoteType(rawValue: noteTypeRawValue) ?? .planner }
        set { noteTypeRawValue = newValue.rawValue }
    }

    var isArchived: Bool { archivedAt != nil }
}
