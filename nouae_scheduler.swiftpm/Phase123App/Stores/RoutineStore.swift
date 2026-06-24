import Foundation
import SwiftData

struct RoutineMaterializationResult {
    let occurrence: RoutineOccurrence
    let block: WorkBlock
}

@MainActor
final class RoutineStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func createRoutine(
        title: String,
        areaId: UUID?,
        projectId: UUID?,
        frequency: RoutineFrequency,
        weekdayMask: Int,
        startMinuteOfDay: Int,
        durationMinutes: Int,
        notes: String = ""
    ) throws -> Routine {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw SyncError.invalidTitle }

        let routine = Routine(
            title: trimmedTitle,
            areaId: areaId,
            projectId: projectId,
            frequency: frequency,
            weekdayMask: weekdayMask,
            startMinuteOfDay: max(0, min(startMinuteOfDay, 23 * 60 + 50)),
            durationMinutes: max(10, durationMinutes),
            notes: notes
        )
        context.insert(routine)
        try context.save()
        return routine
    }

    func activeRoutines(on date: Date) throws -> [Routine] {
        try context.fetch(FetchDescriptor<Routine>())
            .filter { $0.occurs(on: date) }
            .sorted { $0.startMinuteOfDay < $1.startMinuteOfDay }
    }

    @discardableResult
    func ensureOccurrence(for routine: Routine, on date: Date) throws -> RoutineOccurrence {
        let day = Calendar.current.startOfDay(for: date)
        if let existing = try context.fetch(FetchDescriptor<RoutineOccurrence>()).first(where: {
            $0.routineId == routine.id && Calendar.current.isDate($0.occurrenceDate, inSameDayAs: day)
        }) {
            return existing
        }

        let startAt = date(on: day, minuteOfDay: routine.startMinuteOfDay)
        let endAt = Calendar.current.date(byAdding: .minute, value: routine.durationMinutes, to: startAt) ?? startAt
        let occurrence = RoutineOccurrence(
            routineId: routine.id,
            areaId: routine.areaId,
            projectId: routine.projectId,
            title: routine.title,
            occurrenceDate: day,
            plannedStartAt: startAt,
            plannedEndAt: endAt
        )
        context.insert(occurrence)
        try context.save()
        return occurrence
    }

    @discardableResult
    func materializeRoutine(_ routine: Routine, on date: Date) throws -> RoutineMaterializationResult {
        let occurrence = try ensureOccurrence(for: routine, on: date)

        if let workBlockId = occurrence.workBlockId,
           let existing = try context.fetch(FetchDescriptor<WorkBlock>()).first(where: { $0.id == workBlockId }) {
            return RoutineMaterializationResult(occurrence: occurrence, block: existing)
        }

        let project = try findProject(id: routine.projectId)
        let block = WorkBlock(
            title: occurrence.title,
            projectId: routine.projectId,
            startAt: occurrence.plannedStartAt,
            endAt: occurrence.plannedEndAt
        )
        block.calendarIdentifier = project?.calendarIdentifier
        block.syncState = .pending
        context.insert(block)
        occurrence.projectId = routine.projectId
        occurrence.workBlockId = block.id
        occurrence.state = .placed
        occurrence.updatedAt = Date()
        try context.save()
        return RoutineMaterializationResult(occurrence: occurrence, block: block)
    }

    func skipOccurrence(_ occurrence: RoutineOccurrence) throws {
        occurrence.state = .skipped
        occurrence.updatedAt = Date()
        try context.save()
    }

    func archiveRoutine(_ routine: Routine) throws {
        routine.archivedAt = Date()
        routine.isActive = false
        routine.updatedAt = Date()
        try context.save()
    }

    private func findProject(id: UUID?) throws -> Project? {
        guard let id else { return nil }
        return try context.fetch(FetchDescriptor<Project>()).first { $0.id == id }
    }

    private func date(on day: Date, minuteOfDay: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minuteOfDay, to: Calendar.current.startOfDay(for: day)) ?? day
    }
}
