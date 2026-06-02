import SwiftUI

extension Color {
    init(calendarHex: String?) {
        guard let calendarHex, let value = UInt64(calendarHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) else { self = .secondary; return }
        self = Color(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}
