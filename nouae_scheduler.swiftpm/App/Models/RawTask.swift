import Foundation

struct RawTask: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var memo: String?
    var category: ScheduleCategory
    var projectId: UUID?
    var createdAt: Date
    var dueAt: Date?
    var repeatRule: String?
    var isConvertedToBlock: Bool

    init(id: UUID = UUID(), title: String, memo: String? = nil, category: ScheduleCategory, projectId: UUID? = nil, createdAt: Date = Date(), dueAt: Date? = nil, repeatRule: String? = nil, isConvertedToBlock: Bool = false) {
        self.id = id
        self.title = title
        self.memo = memo
        self.category = category
        self.projectId = projectId
        self.createdAt = createdAt
        self.dueAt = dueAt
        self.repeatRule = repeatRule
        self.isConvertedToBlock = isConvertedToBlock
    }
}
