import Foundation

enum TemplateDatabase {
    struct TemplateSection {
        let sectionType: ProjectSectionType
        let title: String
        let content: String
    }

    static func sections(for type: ProjectType) -> [TemplateSection] {
        switch type {
        case .study:
            return base(["목표", "커리큘럼", "약점", "Observation", "Experiment", "Insight", "다음 조정", "링크"])
        case .exercise:
            return base(["목표", "루틴", "컨디션", "Recovery", "Experiment", "Insight", "다음 조정", "링크"])
        case .creative:
            return base(["목적", "레퍼런스", "실험", "실패", "산출물", "Synthesis", "다음 조정", "링크"])
        case .portfolio:
            return base(["목표", "구성", "산출물", "Observation", "Failure", "Insight", "Synthesis", "다음 조정", "링크"])
        case .work:
            return base(["목적", "주요 업무", "이슈", "Experiment", "Insight", "다음 액션", "링크"])
        case .personal:
            return base(["목표", "메모", "Observation", "Insight", "Evolution", "다음 조정", "링크"])
        }
    }

    private static func base(_ titles: [String]) -> [TemplateSection] {
        titles.map { title in
            TemplateSection(sectionType: sectionType(for: title), title: title, content: "")
        }
    }

    private static func sectionType(for title: String) -> ProjectSectionType {
        let value = title.lowercased()
        if value.contains("목표") || value.contains("목적") { return .goal }
        if value.contains("링크") { return .link }
        if value.contains("조정") || value.contains("액션") { return .nextAdjustment }
        if value.contains("observation") || value.contains("컨디션") { return .observation }
        if value.contains("experiment") || value.contains("실험") { return .experiment }
        if value.contains("failure") || value.contains("실패") || value.contains("이슈") { return .failure }
        if value.contains("insight") { return .insight }
        if value.contains("synthesis") { return .synthesis }
        if value.contains("evolution") { return .evolution }
        if value.contains("산출물") { return .output }
        return .memo
    }
}
