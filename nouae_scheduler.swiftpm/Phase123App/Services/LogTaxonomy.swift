import Foundation

struct MoodTagDefinition: Identifiable, Hashable {
    let id: String
    let group: String
    let title: String

    init(group: String, title: String) {
        self.group = group
        self.title = title
        id = "\(group)-\(title)"
    }
}

struct BlockerTagDefinition: Identifiable, Hashable {
    let id: String
    let group: String
    let title: String

    init(group: String, title: String) {
        self.group = group
        self.title = title
        id = "\(group)-\(title)"
    }
}

struct LogTagGroup: Identifiable, Hashable {
    let title: String
    let tags: [String]

    var id: String { title }
}

enum LogTaxonomy {
    static let moodGroups: [LogTagGroup] = [
        LogTagGroup(title: "Focus / Drive", tags: ["집중", "몰입", "창작욕", "추진력"]),
        LogTagGroup(title: "Calm / Recovery", tags: ["평온", "회복", "안정", "여유"]),
        LogTagGroup(title: "Strain / Load", tags: ["피로", "과부하", "긴장", "압박"]),
        LogTagGroup(title: "Low Energy", tags: ["무기력", "산만", "둔함", "지침"]),
        LogTagGroup(title: "Positive Completion", tags: ["만족", "자신감", "해소", "정리됨"]),
        LogTagGroup(title: "Uncertainty", tags: ["불안", "막막함", "혼란", "망설임"])
    ]

    static let blockerGroups: [LogTagGroup] = [
        LogTagGroup(title: "Time", tags: ["시간부족", "일정충돌", "예상시간오차"]),
        LogTagGroup(title: "Focus", tags: ["집중저하", "산만함", "전환비용"]),
        LogTagGroup(title: "Energy", tags: ["피로", "컨디션저하", "회복부족"]),
        LogTagGroup(title: "Clarity", tags: ["정보부족", "기준불명확", "목표흐림"]),
        LogTagGroup(title: "Planning", tags: ["계획과다", "작업단위큼", "우선순위혼란"]),
        LogTagGroup(title: "Environment", tags: ["외부방해", "소음", "장소부적합"]),
        LogTagGroup(title: "Emotion", tags: ["부담감", "막막함", "긴장"]),
        LogTagGroup(title: "Relationship", tags: ["커뮤니케이션대기", "피드백대기", "협업지연"])
    ]

    static var moodDefinitions: [MoodTagDefinition] {
        moodGroups.flatMap { group in
            group.tags.map { MoodTagDefinition(group: group.title, title: $0) }
        }
    }

    static var blockerDefinitions: [BlockerTagDefinition] {
        blockerGroups.flatMap { group in
            group.tags.map { BlockerTagDefinition(group: group.title, title: $0) }
        }
    }
}
