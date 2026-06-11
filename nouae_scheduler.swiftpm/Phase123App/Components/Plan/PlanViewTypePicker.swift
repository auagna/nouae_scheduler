import SwiftUI

enum PlanViewType: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

struct PlanViewTypePicker: View {
    @Binding var selection: PlanViewType

    var body: some View {
        Picker("Plan View", selection: $selection) {
            ForEach(PlanViewType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
}
