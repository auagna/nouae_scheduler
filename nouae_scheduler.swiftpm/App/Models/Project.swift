import Foundation

struct Project: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var type: ProjectType
    var category: ScheduleCategory
    var status: ProjectStatus
    var purpose: String
    var note: String?
    var calendarIdentifier: String?
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    init(id: UUID = UUID(), title: String, type: ProjectType, category: ScheduleCategory, status: ProjectStatus = .planning, purpose: String = "", note: String? = nil, calendarIdentifier: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.category = category
        self.status = status
        self.purpose = purpose
        self.note = note
        self.calendarIdentifier = calendarIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }

    var isArchived: Bool {
        status == .archived || archivedAt != nil
    }

    enum CodingKeys: String, CodingKey {
        case id, title, type, category, status, purpose, note, calendarIdentifier, createdAt, updatedAt, archivedAt, isArchived
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        type = try container.decodeIfPresent(ProjectType.self, forKey: .type) ?? .work
        category = try container.decodeIfPresent(ScheduleCategory.self, forKey: .category) ?? .work
        let legacyArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        status = try container.decodeIfPresent(ProjectStatus.self, forKey: .status) ?? (legacyArchived ? .archived : .planning)
        purpose = try container.decodeIfPresent(String.self, forKey: .purpose) ?? ""
        note = try container.decodeIfPresent(String.self, forKey: .note)
        calendarIdentifier = try container.decodeIfPresent(String.self, forKey: .calendarIdentifier)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        if legacyArchived && archivedAt == nil {
            archivedAt = updatedAt
        }
    }
}
