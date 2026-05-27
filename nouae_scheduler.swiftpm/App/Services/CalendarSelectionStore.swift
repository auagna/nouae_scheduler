import Foundation

@MainActor
final class CalendarSelectionStore: ObservableObject {
    @Published private(set) var selectedCalendarIds: Set<String> = []

    private let defaultsKey = "selectedCalendarIds"
    private let defaults = UserDefaults.standard

    init() {
        selectedCalendarIds = Set(defaults.stringArray(forKey: defaultsKey) ?? [])
    }

    var hasSavedSelection: Bool {
        defaults.object(forKey: defaultsKey) != nil
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
        save()
    }

    func selectAll(_ sources: [CalendarSource]) {
        selectedCalendarIds = Set(sources.map(\.id))
        save()
    }

    func deselectAll() {
        selectedCalendarIds = []
        save()
    }

    func selectedIds(from sources: [CalendarSource]) -> [String] {
        if !hasSavedSelection {
            return sources.map(\.id)
        }
        return sources.filter(\.isSelected).map(\.id)
    }

    private func save() {
        defaults.set(Array(selectedCalendarIds), forKey: defaultsKey)
    }
}
