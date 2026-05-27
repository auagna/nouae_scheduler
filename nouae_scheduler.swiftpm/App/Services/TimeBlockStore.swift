import Foundation

@MainActor
final class TimeBlockStore: ObservableObject {
    @Published private(set) var blocks: [TimeBlock] = []
    @Published var message: String?

    private static let defaultsKey = "nouae.timeBlocks"
    private let eventKitManager: EventKitManager
    private let projectStore: ProjectStore
    private let calendarSelectionStore: CalendarSelectionStore
    private var syncTasks: [UUID: Task<Void, Never>] = [:]
    private let snapMinutes = 15

    init(eventKitManager: EventKitManager, projectStore: ProjectStore, calendarSelectionStore: CalendarSelectionStore) {
        self.eventKitManager = eventKitManager
        self.projectStore = projectStore
        self.calendarSelectionStore = calendarSelectionStore
        blocks = Self.loadPersistedBlocks().filter { Calendar.current.isDateInToday($0.startAt) }
    }

    deinit { syncTasks.values.forEach { $0.cancel() } }

    static func loadPersistedBlocks() -> [TimeBlock] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return [] }
        return (try? JSONDecoder().decode([TimeBlock].self, from: data)) ?? []
    }

    func loadToday() async {
        let persistedToday = Self.loadPersistedBlocks().filter { Calendar.current.isDateInToday($0.startAt) }
        if !persistedToday.isEmpty {
            blocks = persistedToday.sorted { $0.startAt < $1.startAt }
            return
        }

        do {
            blocks = try await eventKitManager.fetchTodayTimeBlocks()
            persistBlocks()
            message = nil
        } catch { message = error.localizedDescription }
    }

    func createBlock(title: String, category: ScheduleCategory, project: Project?, startAt: Date, endAt: Date) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            message = "일정 제목을 입력해 주세요."
            return
        }

        let resolvedCategory = project?.category ?? category
        let normalizedStart = snapped(startAt)
        let normalizedEnd = max(snapped(endAt), Calendar.current.date(byAdding: .minute, value: 30, to: normalizedStart) ?? endAt)
        let block = TimeBlock(
            title: cleanTitle,
            category: resolvedCategory,
            startAt: normalizedStart,
            endAt: normalizedEnd,
            calendarIdentifier: project?.calendarIdentifier ?? calendarSelectionStore.calendarId(for: resolvedCategory),
            syncStatus: .pending,
            projectId: project?.id,
            projectTitle: project?.title
        )
        blocks.append(block)
        sortBlocks()
        persistBlocks()
        scheduleSync(for: block.id)
    }

    func moveBlock(id: UUID, byMinutes deltaMinutes: Int) {
        updateBlock(id: id) { block in
            block.startAt = snapped(Calendar.current.date(byAdding: .minute, value: deltaMinutes, to: block.startAt) ?? block.startAt)
            block.endAt = snapped(Calendar.current.date(byAdding: .minute, value: deltaMinutes, to: block.endAt) ?? block.endAt)
            clampToToday(&block)
        }
    }

    func resizeBlockStart(id: UUID, byMinutes deltaMinutes: Int) {
        updateBlock(id: id) { block in
            let newStart = snapped(Calendar.current.date(byAdding: .minute, value: deltaMinutes, to: block.startAt) ?? block.startAt)
            if let latestStart = Calendar.current.date(byAdding: .minute, value: -15, to: block.endAt) {
                block.startAt = min(newStart, latestStart)
            }
            clampToToday(&block)
        }
    }

    func resizeBlockEnd(id: UUID, byMinutes deltaMinutes: Int) {
        updateBlock(id: id) { block in
            let newEnd = snapped(Calendar.current.date(byAdding: .minute, value: deltaMinutes, to: block.endAt) ?? block.endAt)
            if let earliestEnd = Calendar.current.date(byAdding: .minute, value: 15, to: block.startAt) {
                block.endAt = max(newEnd, earliestEnd)
            }
            clampToToday(&block)
        }
    }

    private func updateBlock(id: UUID, mutate: (inout TimeBlock) -> Void) {
        guard let index = blocks.firstIndex(where: { $0.id == id }) else { return }
        mutate(&blocks[index])
        blocks[index].syncStatus = .pending
        sortBlocks()
        persistBlocks()
        scheduleSync(for: id)
    }

    private func scheduleSync(for id: UUID) {
        syncTasks[id]?.cancel()
        syncTasks[id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.sync(id: id)
        }
    }

    private func sync(id: UUID) async {
        guard let index = blocks.firstIndex(where: { $0.id == id }) else { return }
        blocks[index].syncStatus = .syncing
        persistBlocks()

        do {
            let resolvedBlock = try await blockWithResolvedCalendar(blocks[index])
            let savedBlock = try await eventKitManager.saveTimeBlock(resolvedBlock)
            if let savedIndex = blocks.firstIndex(where: { $0.id == id }) {
                blocks[savedIndex] = savedBlock
                sortBlocks()
                persistBlocks()
            }
            message = nil
        } catch {
            if let failedIndex = blocks.firstIndex(where: { $0.id == id }) {
                blocks[failedIndex].syncStatus = .failed
                persistBlocks()
            }
            message = error.localizedDescription
        }
    }

    private func blockWithResolvedCalendar(_ block: TimeBlock) async throws -> TimeBlock {
        var resolved = block
        if let project = projectStore.project(id: block.projectId), let calendarIdentifier = project.calendarIdentifier {
            resolved.calendarIdentifier = calendarIdentifier
            return resolved
        }

        let category = projectStore.project(id: block.projectId)?.category ?? block.category
        let calendars = (try? await eventKitManager.fetchCalendars()) ?? []
        if let mappedCalendarId = calendarSelectionStore.calendarId(for: category, in: calendars) {
            resolved.calendarIdentifier = mappedCalendarId
            return resolved
        }

        throw EventKitManagerError.validation("\(category.rawValue) 카테고리에 연결된 Apple Calendar가 없습니다. Calendar 탭 필터에서 카테고리 캘린더를 연결해 주세요.")
    }

    private func sortBlocks() { blocks.sort { $0.startAt < $1.startAt } }

    private func persistBlocks() {
        var allBlocks = Self.loadPersistedBlocks()
        let currentIds = Set(blocks.map(\.id))
        allBlocks.removeAll { currentIds.contains($0.id) || Calendar.current.isDateInToday($0.startAt) }
        allBlocks.append(contentsOf: blocks)
        if let data = try? JSONEncoder().encode(allBlocks) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    private func snapped(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return date }
        let snappedMinute = Int((Double(minute) / Double(snapMinutes)).rounded()) * snapMinutes
        var newComponents = components
        newComponents.minute = snappedMinute % 60
        newComponents.hour = hour + snappedMinute / 60
        newComponents.second = 0
        return calendar.date(from: newComponents) ?? date
    }

    private func clampToToday(_ block: inout TimeBlock) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: block.startAt)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? block.endAt
        let duration = block.endAt.timeIntervalSince(block.startAt)

        if block.startAt < dayStart {
            block.startAt = dayStart
            block.endAt = block.startAt.addingTimeInterval(duration)
        }
        if block.endAt > dayEnd {
            block.endAt = dayEnd
            block.startAt = block.endAt.addingTimeInterval(-duration)
        }
    }
}
