import SwiftUI

struct PlanSettingsSection: View {
    @AppStorage("nouae.plan.defaultDurationMinutes") private var defaultDuration = 10
    @AppStorage("nouae.plan.snapUnitMinutes") private var snapUnit = 10
    @AppStorage("nouae.plan.visibleStartHour") private var visibleStartHour = 6
    @AppStorage("nouae.plan.visibleEndHour") private var visibleEndHour = 23

    var body: some View {
        AppPanel(title: "Plan Settings", subtitle: "HourGrid Time Assembly Board 기본값입니다.") {
            Stepper("Default WorkBlock Duration: \(defaultDuration) minutes", value: $defaultDuration, in: 10...180, step: 10)
            Picker("Snap Unit", selection: $snapUnit) {
                Text("10 minutes").tag(10)
            }
            .pickerStyle(.segmented)
            Stepper("Visible Start Hour: \(visibleStartHour):00", value: $visibleStartHour, in: 0...23)
            Stepper("Visible End Hour: \(visibleEndHour):00", value: $visibleEndHour, in: 0...23)
        }
        .onChange(of: visibleStartHour) { _, newValue in
            if visibleEndHour < newValue {
                visibleEndHour = newValue
            }
        }
        .onChange(of: visibleEndHour) { _, newValue in
            if newValue < visibleStartHour {
                visibleStartHour = newValue
            }
        }
    }
}
