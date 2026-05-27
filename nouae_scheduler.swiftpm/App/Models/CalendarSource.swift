import Foundation

struct CalendarSource: Identifiable, Equatable {
    let id: String
    let title: String
    let colorHex: String?
    var isSelected: Bool
}
