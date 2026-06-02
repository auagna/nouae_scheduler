import SwiftUI

extension Color {
    init(calendarHex: String?) {
        guard let calendarHex else {
            self = .secondary
            return
        }
        let hex = calendarHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else {
            self = .secondary
            return
        }
        self = Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
