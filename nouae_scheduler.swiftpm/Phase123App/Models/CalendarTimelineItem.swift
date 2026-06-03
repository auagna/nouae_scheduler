import Foundation

struct CalendarTimelineItem: Identifiable {
    let id: String
    let title: String
    let startAt: Date
    let endAt: Date
    let calendarIdentifier: String?
    let colorHex: String?
    let projectId: UUID?
    let workBlockId: UUID?
    let externalEventIdentifier: String?
    let isLocalOnly: Bool

    static func local(block: WorkBlock, project: Project?) -> CalendarTimelineItem {
        CalendarTimelineItem(
            id: "local-\(block.id.uuidString)",
            title: block.title,
            startAt: block.startAt,
            endAt: block.endAt,
            calendarIdentifier: block.calendarIdentifier,
            colorHex: project?.calendarColorHex,
            projectId: block.projectId,
            workBlockId: block.id,
            externalEventIdentifier: block.eventIdentifier,
            isLocalOnly: true
        )
    }
}
