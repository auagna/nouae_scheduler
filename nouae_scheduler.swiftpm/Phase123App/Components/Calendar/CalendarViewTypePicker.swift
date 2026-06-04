import SwiftUI

struct CalendarViewTypePicker: View {
    @Binding var selection: CalendarViewType

    var body: some View {
        Picker("View Type", selection: $selection) {
            ForEach(CalendarViewType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
}
