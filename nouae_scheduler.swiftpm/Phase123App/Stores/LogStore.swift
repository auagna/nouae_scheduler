import Foundation
import SwiftData

@MainActor
final class LogStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createLog(
        logType: LogType = .daily,
        areaId: UUID? = nil,
        projectId: UUID?,
        workBlockId: UUID?,
        title: String = "",
        focusLevel: Int?,
        moodTags: [String] = [],
        blockerTags: [String],
        blockerNote: String,
        nextAdjustment: String,
        content: String
    ) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAdjustment = nextAdjustment.trimmingCharacters(in: .whitespacesAndNewlines)
        let log = ProjectLog(
            logType: logType,
            areaId: areaId,
            projectId: projectId,
            workBlockId: workBlockId,
            title: trimmedTitle.isEmpty ? logType.title : trimmedTitle,
            focusLevel: focusLevel,
            moodTags: moodTags,
            blockerTags: blockerTags,
            blockerNote: blockerNote.trimmingCharacters(in: .whitespacesAndNewlines),
            nextAdjustment: trimmedAdjustment,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(log)
        if let projectId, !trimmedAdjustment.isEmpty {
            for item in try context.fetch(FetchDescriptor<NextAdjustment>()).filter({ $0.projectId == projectId }) {
                item.isActive = false
            }
            context.insert(NextAdjustment(projectId: projectId, content: trimmedAdjustment))
        }
        try context.save()
    }

    func fetchRecentLogsByProject(projectId: UUID, limit: Int = 3) throws -> [ProjectLog] {
        let logs = try context.fetch(FetchDescriptor<ProjectLog>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            .filter { $0.projectId == projectId }
        return Array(logs.prefix(limit))
    }

    func logsByDate(_ date: Date) throws -> [ProjectLog] {
        try context.fetch(FetchDescriptor<ProjectLog>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            .filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
    }

    func moodFrequency(days: Int = 7, projectId: UUID? = nil) throws -> [(String, Int)] {
        let start = Calendar.current.date(byAdding: .day, value: -days + 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let logs = try context.fetch(FetchDescriptor<ProjectLog>())
            .filter { $0.createdAt >= start && (projectId == nil || $0.projectId == projectId) }
        return frequency(logs.flatMap(\.moodTags))
    }

    func blockerFrequency(days: Int = 7, projectId: UUID? = nil) throws -> [(String, Int)] {
        let start = Calendar.current.date(byAdding: .day, value: -days + 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let logs = try context.fetch(FetchDescriptor<ProjectLog>())
            .filter { $0.createdAt >= start && (projectId == nil || $0.projectId == projectId) }
        return frequency(logs.flatMap(\.blockerTags))
    }

    private func frequency(_ values: [String]) -> [(String, Int)] {
        Dictionary(grouping: values, by: { $0 })
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 { return lhs.0 < rhs.0 }
                return lhs.1 > rhs.1
            }
    }
}
