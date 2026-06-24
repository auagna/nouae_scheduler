import Foundation
import SwiftData

struct RoutineMaterializationResult {
    let occurrence: RoutineOccurrence
    let block: WorkBlock
}

@MainActor
final class RoutineStore {
    private let context: ModelContext
    private let routinesKey = "nouae.routines.v1"
    private let occurrencesKey = "nouae.routineOccurrences.v1"

    init(context: ModelContext) {
        self.context = context
    }

    var routines: [Routine] {
        loadRoutines()
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

        var routine = Routine(title: trimmedTitle)
        routine.areaId = areaId
        routine.projectId = projectId
        routine.frequency = frequency
        routine.weekdayMask = weekdayMask
        routine.startMinuteOfDay = max(0, min(startMinuteOfDay, 23 * 60 + 50))
        routine.durationMinutes = max(10, durationMinutes)
        routine.notes = notes

        var values = loadRoutines()
        values.insert(routine, at: 0)
        saveRoutines(values)
        return routine
    }

    func activeRoutines(on date: Date) -> [Routine] {
        loadRoutines()
            .filter { $0.occurs(on: date) }
            .sorted { $0.startMinuteOfDay < $1.startMinuteOfDay }
    }

    @discardableResult
    func ensureOccurrence(for routine: Routine, on date: Date) -> RoutineOccurrence {
        let day = Calendar.current.startOfDay(for: date)
        var occurrences = loadOccurrences()

        if let existing = occurrences.first(where: {
            $0.routineId == routine.id && Calendar.current.isDate($0.occurrenceDate, inSameDayAs: day)
        }) {
            return existing
        }

        let startAt = makeDate(on: day, minuteOfDay: routine.startMinuteOfDay)
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
        occurrences.insert(occurrence, at: 0)
        saveOccurrences(occurrences)
        return occurrence
    }

    @discardableResult
    func materializeRoutine(_ routine: Routine, on date: Date) throws -> RoutineMaterializationResult {
        var occurrence = ensureOccurrence(for: routine, on: date)

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
        try context.save()

        occurrence.projectId = routine.projectId
        occurrence.workBlockId = block.id
        occurrence.state = .placed
        occurrence.updatedAt = Date()
        upsertOccurrence(occurrence)
        return RoutineMaterializationResult(occurrence: occurrence, block: block)
    }

    func skipOccurrence(_ occurrence: RoutineOccurrence) {
        var value = occurrence
        value.state = .skipped
        value.updatedAt = Date()
        upsertOccurrence(value)
    }

    func archiveRoutine(_ routine: Routine) {
        var values = loadRoutines()
        guard let index = values.firstIndex(where: { $0.id == routine.id }) else { return }
        values[index].archivedAt = Date()
        values[index].isActive = false
        values[index].updatedAt = Date()
        saveRoutines(values)
    }

    private func findProject(id: UUID?) throws -> Project? {
        guard let id else { return nil }
        return try context.fetch(FetchDescriptor<Project>()).first { $0.id == id }
    }

    private func upsertOccurrence(_ occurrence: RoutineOccurrence) {
        var values = loadOccurrences()
        if let index = values.firstIndex(where: { $0.id == occurrence.id }) {
            values[index] = occurrence
        } else {
            values.insert(occurrence, at: 0)
        }
        saveOccurrences(values)
    }

    private func loadRoutines() -> [Routine] {
        guard let data = UserDefaults.standard.data(forKey: routinesKey) else { return [] }
        return (try? JSONDecoder().decode([Routine].self, from: data)) ?? []
    }

    private func saveRoutines(_ routines: [Routine]) {
        guard let data = try? JSONEncoder().encode(routines) else { return }
        UserDefaults.standard.set(data, forKey: routinesKey)
    }

    private func loadOccurrences() -> [RoutineOccurrence] {
        guard let data = UserDefaults.standard.data(forKey: occurrencesKey) else { return [] }
        return (try? JSONDecoder().decode([RoutineOccurrence].self, from: data)) ?? []
    }

    private func saveOccurrences(_ occurrences: [RoutineOccurrence]) {
        guard let data = try? JSONEncoder().encode(occurrences) else { return }
        UserDefaults.standard.set(data, forKey: occurrencesKey)
    }

    private func makeDate(on day: Date, minuteOfDay: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minuteOfDay, to: Calendar.current.startOfDay(for: day)) ?? day
    }
}
