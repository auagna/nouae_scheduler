import Foundation
import SwiftData

@MainActor
final class WorkBlockStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func createWorkBlock(title: String, projectId: UUID?, startAt: Date, endAt: Date) throws -> WorkBlock {
        let range = DateSnapper.normalizedRange(startAt: startAt, endAt: endAt)
        let block = WorkBlock(title: title, projectId: projectId, startAt: range.startAt, endAt: range.endAt)
        context.insert(block)
        try context.save()
        return block
    }

    func convert(task: RawTask, project: Project?, startAt: Date, endAt: Date) throws -> WorkBlock {
        let range = DateSnapper.normalizedRange(startAt: startAt, endAt: endAt)
        let projectId = project?.id ?? task.projectId
        let calendarIdentifier = project?.calendarIdentifier
        let block = WorkBlock(
            title: task.title,
            projectId: projectId,
            rawTaskId: task.id,
            startAt: range.startAt,
            endAt: range.endAt,
            calendarIdentifier: calendarIdentifier,
            syncState: calendarIdentifier == nil ? .local : .pending
        )
        task.projectId = projectId
        task.isConvertedToBlock = true
        task.scheduledAt = range.startAt
        context.insert(block)
        try context.save()
        return block
    }

    func updateTime(block: WorkBlock, startAt: Date, endAt: Date) throws {
        let range = DateSnapper.normalizedRange(startAt: startAt, endAt: endAt)
        block.startAt = range.startAt
        block.endAt = range.endAt
        block.updatedAt = Date()
        block.syncState = block.calendarIdentifier == nil ? .local : .pending
        try context.save()
    }

    func fetchBlocksByProject(projectId: UUID) throws -> [WorkBlock] {
        try context.fetch(FetchDescriptor<WorkBlock>()).filter { $0.projectId == projectId }
    }

    func fetchTodayBlocksByProject(projectId: UUID) throws -> [WorkBlock] {
        try fetchBlocksByProject(projectId: projectId).filter { Calendar.current.isDateInToday($0.startAt) }
    }

    func calculateProjectProgress(blocks: [WorkBlock]) -> Double {
        blocks.isEmpty ? 0 : Double(blocks.filter { $0.executionState == .completed }.count) / Double(blocks.count)
    }
}
