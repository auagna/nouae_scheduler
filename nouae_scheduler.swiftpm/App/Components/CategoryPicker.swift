import SwiftUI

struct CategoryPicker: View {
    @Binding var selectedCategory: ScheduleCategory

    var body: some View {
        Picker("카테고리", selection: $selectedCategory) {
            ForEach(ScheduleCategory.allCases) { category in
                Label(category.rawValue, systemImage: category.symbolName)
                    .tag(category)
            }
        }
        .pickerStyle(.segmented)
    }
}
