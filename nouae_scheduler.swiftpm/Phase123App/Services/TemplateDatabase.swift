import Foundation

struct ProjectTemplateSection {
    let title: String
    let content: String
}

enum TemplateDatabase {
    static func sections(for type: ProjectType) -> [ProjectTemplateSection] {
        baseSections + typedSections(for: type) + linkSections(for: type)
    }

    private static var baseSections: [ProjectTemplateSection] {
        [
            ProjectTemplateSection(title: "목표", content: "이 프로젝트가 끝났을 때 어떤 상태가 되어야 하는지 적습니다."),
            ProjectTemplateSection(title: "Inbox", content: "아직 시간에 배치하지 않은 생각과 작업을 모읍니다."),
            ProjectTemplateSection(title: "메모", content: "프로젝트를 운영하며 기억해야 할 내용을 남깁니다."),
            ProjectTemplateSection(title: "다음 조정", content: "다음 실행에서 바꿀 한 가지를 적습니다.")
        ]
    }

    private static func typedSections(for type: ProjectType) -> [ProjectTemplateSection] {
        switch type {
        case .study:
            return [
                ProjectTemplateSection(title: "학습 범위", content: "시험, 강의, 교재, 실습 범위를 정리합니다."),
                ProjectTemplateSection(title: "복습 루틴", content: "반복해서 확인할 단원과 주기를 적습니다.")
            ]
        case .work:
            return [
                ProjectTemplateSection(title: "업무 산출물", content: "완료해야 할 문서, 결정, 전달물을 정리합니다."),
                ProjectTemplateSection(title: "이슈", content: "막힌 지점과 확인이 필요한 사람 또는 조건을 적습니다.")
            ]
        case .exercise:
            return [
                ProjectTemplateSection(title: "운동 루틴", content: "운동 종류, 빈도, 기준 강도를 적습니다."),
                ProjectTemplateSection(title: "컨디션", content: "수면, 통증, 회복 상태를 간단히 적습니다.")
            ]
        case .creative:
            return [
                ProjectTemplateSection(title: "콘셉트", content: "만들고 싶은 분위기, 참고, 핵심 아이디어를 적습니다."),
                ProjectTemplateSection(title: "작업 조각", content: "스케치, 원고, 샘플 등 작은 단위의 진행 조각을 적습니다.")
            ]
        case .portfolio:
            return [
                ProjectTemplateSection(title: "대표 메시지", content: "이 프로젝트가 보여줄 역량과 이야기를 정리합니다."),
                ProjectTemplateSection(title: "증거 자료", content: "이미지, 링크, 결과물, 수치를 모읍니다.")
            ]
        case .personal:
            return [
                ProjectTemplateSection(title: "개인 기준", content: "이 프로젝트를 지속할 나만의 기준을 적습니다."),
                ProjectTemplateSection(title: "생활 연결", content: "일상 시간, 장소, 습관과 어떻게 연결할지 적습니다.")
            ]
        }
    }

    private static func linkSections(for type: ProjectType) -> [ProjectTemplateSection] {
        [
            ProjectTemplateSection(title: "링크", content: "관련 링크, 파일 위치, 참고 자료를 모읍니다."),
            ProjectTemplateSection(title: "리포트 메모", content: "Dashboard에서 보고받고 싶은 요약 기준을 적습니다.")
        ]
    }
}
