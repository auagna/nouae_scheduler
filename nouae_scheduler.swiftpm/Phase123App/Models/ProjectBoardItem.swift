import Foundation
import SwiftData

enum ProjectBoardItemType: String, CaseIterable, Identifiable {
    case note
    case quote
    case link
    case image
    case sketch
    case color
    case material
    case reference
    case experiment
    case insight
    case output

    var id: String { rawValue }

    var title: String {
        switch self {
        case .note: return "Note"
        case .quote: return "Quote"
        case .link: return "Link"
        case .image: return "Image"
        case .sketch: return "Sketch"
        case .color: return "Color"
        case .material: return "Material"
        case .reference: return "Reference"
        case .experiment: return "Experiment"
        case .insight: return "Insight"
        case .output: return "Output"
        }
    }

    var symbolName: String {
        switch self {
        case .note: return "note.text"
        case .quote: return "quote.opening"
        case .link: return "link"
        case .image: return "photo"
        case .sketch: return "pencil.and.scribble"
        case .color: return "paintpalette"
        case .material: return "square.stack.3d.down.right"
        case .reference: return "bookmark"
        case .experiment: return "flask"
        case .insight: return "sparkle.magnifyingglass"
        case .output: return "shippingbox"
        }
    }
}

@Model
final class ProjectBoardItem {
    @Attribute(.unique) var id: UUID
    var projectId: UUID
    var itemTypeRawValue: String
    var title: String
    var content: String
    var url: String
    var imageData: Data?
    var drawingData: Data?
    var colorHex: String?
    var positionX: Double
    var positionY: Double
    var width: Double
    var height: Double
    var order: Int
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        projectId: UUID,
        itemType: ProjectBoardItemType = .note,
        title: String = "",
        content: String = "",
        url: String = "",
        imageData: Data? = nil,
        drawingData: Data? = nil,
        colorHex: String? = nil,
        positionX: Double = 0,
        positionY: Double = 0,
        width: Double = 180,
        height: Double = 140,
        order: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.projectId = projectId
        itemTypeRawValue = itemType.rawValue
        self.title = title.isEmpty ? itemType.title : title
        self.content = content
        self.url = url
        self.imageData = imageData
        self.drawingData = drawingData
        self.colorHex = colorHex
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

extension ProjectBoardItem {
    var itemType: ProjectBoardItemType {
        get { ProjectBoardItemType(rawValue: itemTypeRawValue) ?? .note }
        set { itemTypeRawValue = newValue.rawValue }
    }

    var isArchived: Bool { archivedAt != nil }
}
