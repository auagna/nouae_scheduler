import Foundation

@MainActor
final class CalendarSelectionStore: ObservableObject {
    @Published private(set) var selectedCalendarIds: Set<String> = []
    @Published private(set) var categoryCalendarIds: [ScheduleCategory: String] = [:]

    private let selectedDefaultsKey = "selectedCalendarIds"
    private let categoryMappingDefaultsKey = "categoryCalendarIds"
    private let defaults = UserDefaults.standard

    init() {
        selectedCalendarIds = Set(defaults.stringArray(forKey: selectedDefaultsKey) ?? [])
        categoryCalendarIds = loadCategoryMappings()
    }

    var hasSavedSelection: Bool {
        defaults.object(forKey: selectedDefaultsKey) != nil
    }

    func applySelection(to sources: [CalendarSource]) -> [CalendarSource] {
        if !hasSavedSelection {
            return sources.map { source in
                var selectedSource = source
                selectedSource.isSelected = true
                return selectedSource
            }
        }

        return sources.map { source in
            var selectedSource = source
            selectedSource.isSelected = selectedCalendarIds.contains(source.id)
            return selectedSource
        }
    }

    func setSelected(_ isSelected: Bool, for sourceId: String) {
        if isSelected {
            selectedCalendarIds.insert(sourceId)
        } else {
            selectedCalendarIds.remove(sourceId)
        }
        saveSelectedCalendarIds()
    }

    func selectAll(_ sources: [CalendarSource]) {
        selectedCalendarIds = Set(sources.map(\.id))
        saveSelectedCalendarIds()
    }

    func deselectAll() {
        selectedCalendarIds = []
        saveSelectedCalendarIds()
    }

    func selectedIds(from sources: [CalendarSource]) -> [String] {
        if !hasSavedSelection {
            return sources.map(\.id)
        }
        return sources.filter(\.isSelected).map(\.id)
    }

    func setCalendarSource(_ sourceId: String?, for category: ScheduleCategory) {
        categoryCalendarIds[category] = sourceId
        saveCategoryMappings()
    }

    func calendarId(for category: ScheduleCategory) -> String? {
        categoryCalendarIds[category]
    }

    private func saveSelectedCalendarIds() {
        defaults.set(Array(selectedCalendarIds), forKey: selectedDefaultsKey)
    }

    private func loadCategoryMappings() -> [ScheduleCategory: String] {
        guard let stored = defaults.dictionary(forKey: categoryMappingDefaultsKey) as? [String: String] else {
            return [:]
        }

        var mappings: [ScheduleCategory: String] = [:]
        for (rawCategory, calendarId) in stored {
            if let category = ScheduleCategory(rawValue: rawCategory) {
                mappings[category] = calendarId
            }
        }
        return mappings
    }

    private func saveCategoryMappings() {
        let stored = Dictionary(uniqueKeysWithValues: categoryCalendarIds.map { category, calendarId in
            (category.rawValue, calendarId)
        })
        defaults.set(stored, forKey: categoryMappingDefaultsKey)
    }
}
