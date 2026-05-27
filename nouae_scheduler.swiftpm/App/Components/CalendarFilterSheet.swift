import SwiftUI

struct CalendarFilterSheet: View {
    @Binding var sources: [CalendarSource]
    @ObservedObject var selectionStore: CalendarSelectionStore
    let onSelectionChanged: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                HStack {
                    Button("전체 선택") {
                        selectionStore.selectAll(sources)
                        updateSources()
                        onSelectionChanged()
                    }
                    Spacer()
                    Button("전체 해제") {
                        selectionStore.deselectAll()
                        updateSources()
                        onSelectionChanged()
                    }
                }
            }

            Section("카테고리 캘린더 매핑") {
                ForEach(ScheduleCategory.allCases) { category in
                    Picker(category.rawValue, selection: Binding(
                        get: { selectionStore.calendarId(for: category, in: sources) },
                        set: { selectionStore.setCalendarSource($0, for: category) }
                    )) {
                        Text("연결 필요").tag(String?.none)
                        ForEach(sources) { source in
                            Text(source.title).tag(Optional(source.id))
                        }
                    }
                }
            }

            Section("표시할 캘린더") {
                ForEach($sources) { $source in
                    Toggle(isOn: Binding(
                        get: { source.isSelected },
                        set: { isSelected in
                            if !selectionStore.hasSavedSelection {
                                selectionStore.selectAll(sources)
                            }
                            source.isSelected = isSelected
                            selectionStore.setSelected(isSelected, for: source.id)
                            updateSources()
                            onSelectionChanged()
                        }
                    )) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: source.colorHex) ?? .accentColor)
                                .frame(width: 12, height: 12)
                            Text(source.title)
                        }
                    }
                }
            }
        }
        .navigationTitle("캘린더 선택")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("완료") { dismiss() }
            }
        }
    }

    private func updateSources() {
        sources = selectionStore.applySelection(to: sources)
    }
}
