import Foundation
import SwiftData

@MainActor
final class ProjectNoteStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func ensureNote(areaId: UUID?, projectId: UUID?, type: ProjectNoteType, title: String? = nil) throws -> ProjectNote {
        if let existing = try context.fetch(FetchDescriptor<ProjectNote>()).first(where: {
            $0.areaId == areaId && $0.projectId == projectId && $0.noteType == type && $0.archivedAt == nil
        }) {
            return existing
        }

        let note = ProjectNote(
            areaId: areaId,
            projectId: projectId,
            noteType: type,
            title: title ?? type.title,
            content: defaultContent(for: type)
        )
        context.insert(note)
        try context.save()
        return note
    }

    func ensureDefaultNotes(areaId: UUID?, projectId: UUID?, projectTitle: String) throws {
        for type in ProjectNoteType.allCases {
            _ = try ensureNote(areaId: areaId, projectId: projectId, type: type, title: type.title)
        }
    }

    func notes(areaId: UUID?, projectId: UUID?) throws -> [ProjectNote] {
        try context.fetch(FetchDescriptor<ProjectNote>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
            .filter { $0.areaId == areaId && $0.projectId == projectId && $0.archivedAt == nil }
    }

    func update(note: ProjectNote, title: String, content: String) throws {
        note.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        note.content = content
        note.updatedAt = Date()
        try context.save()
    }

    func archive(note: ProjectNote) throws {
        note.archivedAt = Date()
        note.updatedAt = Date()
        try context.save()
    }

    private func defaultContent(for type: ProjectNoteType) -> String {
        switch type {
        case .workJournal:
            return "오늘 움직인 업무 흐름을 짧게 남깁니다."
        case .diary:
            return "하루의 상태와 생각을 조용히 기록합니다."
        case .planner:
            return "다음에 조립할 시간과 작업을 적어 둡니다."
        case .reflection:
            return "무엇이 작동했고 무엇이 막혔는지 정리합니다."
        case .studio:
            return "작업실에서 붙잡고 있는 재료, 방향, 참고를 모읍니다."
        case .experiment:
            return "시도할 가설과 결과를 짧게 기록합니다."
        case .sketch:
            return "스케치 데이터 저장 구조가 준비되어 있습니다. 고급 드로잉은 이후 Calendar Drawing과 공통화합니다."
        }
    }
}
