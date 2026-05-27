enum ProjectType: String, CaseIterable, Identifiable, Codable {
    case study = "학습"
    case work = "업무"
    case exercise = "운동"
    case creative = "창작"
    case portfolio = "포트폴리오"
    case personal = "개인"

    var id: String { rawValue }
}
