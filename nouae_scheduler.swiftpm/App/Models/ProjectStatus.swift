enum ProjectStatus: String, CaseIterable, Identifiable, Codable {
    case planning = "계획"
    case scheduled = "배치됨"
    case active = "진행중"
    case completed = "완료"
    case archived = "보관"

    var id: String { rawValue }
}
