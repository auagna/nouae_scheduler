import Foundation
import SwiftData

enum ModuleOrigin: String, CaseIterable, Identifiable, Codable {
    case builtIn
    case user
    case adminPack
    var id: String { rawValue }
}

enum ModuleCategory: String, CaseIterable, Identifiable, Codable {
    case planning
    case calendar
    case project
    case reflection
    case routine
    case tracker
    case creative
    case utility
    var id: String { rawValue }
}

enum ModulePlacement: String, CaseIterable, Identifiable, Codable {
    case dashboardCompact
    case dashboardContext
    case projectDashboardContext
    case projectPageBlock
    case projectNotesTool
    case planQuickAction
    case routineTemplate
    case calendarOverlay
    case logPreset
    case trackerMetric
    case settingsSection

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboardCompact: return "Dashboard Compact"
        case .dashboardContext: return "Dashboard Context"
        case .projectDashboardContext: return "Project Dashboard"
        case .projectPageBlock: return "Project Page"
        case .projectNotesTool: return "Project Notes"
        case .planQuickAction: return "Plan Quick Action"
        case .routineTemplate: return "Routine Template"
        case .calendarOverlay: return "Calendar Overlay"
        case .logPreset: return "Log Preset"
        case .trackerMetric: return "Tracker Metric"
        case .settingsSection: return "Settings"
        }
    }
}

enum ModuleCapability: String, CaseIterable, Identifiable, Codable {
    case readAreas
    case readProjects
    case readTasks
    case readWorkBlocks
    case readLogs
    case readNotes
    case readRoutines
    case readTrackerSummary
    case readCalendarSummary
    case readReminderSummary
    case createTask
    case updateTask
    case createWorkBlock
    case createLog
    case createNote
    case createRoutine
    case createAdjustment
    case openProject
    case openPlan
    case openCalendar
    case openLog
    case exportModuleData
    case directEventKitAccess
    case directPhotoLibraryAccess
    case arbitraryFileAccess
    case executeCode
    case networkRequest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .readAreas: return "Area 읽기"
        case .readProjects: return "Project 읽기"
        case .readTasks: return "Task 읽기"
        case .readWorkBlocks: return "WorkBlock 읽기"
        case .readLogs: return "Log 읽기"
        case .readNotes: return "Note 읽기"
        case .readRoutines: return "Routine 읽기"
        case .readTrackerSummary: return "Tracker Summary 읽기"
        case .readCalendarSummary: return "Calendar Summary 읽기"
        case .readReminderSummary: return "Reminder Summary 읽기"
        case .createTask: return "Task 생성"
        case .updateTask: return "Task 수정"
        case .createWorkBlock: return "WorkBlock 생성"
        case .createLog: return "Log 생성"
        case .createNote: return "Note 생성"
        case .createRoutine: return "Routine 생성"
        case .createAdjustment: return "Adjustment 생성"
        case .openProject: return "Project 열기"
        case .openPlan: return "Plan 열기"
        case .openCalendar: return "Calendar 열기"
        case .openLog: return "Log 열기"
        case .exportModuleData: return "Module Data 내보내기"
        case .directEventKitAccess: return "직접 EventKit 접근"
        case .directPhotoLibraryAccess: return "직접 Photo Library 접근"
        case .arbitraryFileAccess: return "임의 파일 접근"
        case .executeCode: return "외부 코드 실행"
        case .networkRequest: return "네트워크 요청"
        }
    }

    var isForbidden: Bool {
        switch self {
        case .directEventKitAccess, .directPhotoLibraryAccess, .arbitraryFileAccess, .executeCode, .networkRequest:
            return true
        default:
            return false
        }
    }
}

enum ModuleEntryType: String, CaseIterable, Identifiable, Codable {
    case native
    case declarative
    var id: String { rawValue }
}

struct ModuleManifest: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var descriptionText: String
    var version: String
    var author: String
    var categoryRawValue: String
    var iconSystemName: String
    var originRawValue: String
    var minimumAppVersion: String
    var schemaVersion: Int
    var placementsRawValue: String
    var capabilitiesRawValue: String
    var entryTypeRawValue: String
    var isEnabledByDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        name: String,
        descriptionText: String,
        version: String = "1.0",
        author: String = "nou ae",
        category: ModuleCategory,
        iconSystemName: String,
        origin: ModuleOrigin,
        minimumAppVersion: String = "1.0",
        schemaVersion: Int = 1,
        placements: [ModulePlacement],
        capabilities: [ModuleCapability],
        entryType: ModuleEntryType,
        isEnabledByDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.version = version
        self.author = author
        categoryRawValue = category.rawValue
        self.iconSystemName = iconSystemName
        originRawValue = origin.rawValue
        self.minimumAppVersion = minimumAppVersion
        self.schemaVersion = schemaVersion
        placementsRawValue = placements.map(\.rawValue).joined(separator: ",")
        capabilitiesRawValue = capabilities.map(\.rawValue).joined(separator: ",")
        entryTypeRawValue = entryType.rawValue
        self.isEnabledByDefault = isEnabledByDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension ModuleManifest {
    var origin: ModuleOrigin { ModuleOrigin(rawValue: originRawValue) ?? .user }
    var entryType: ModuleEntryType { ModuleEntryType(rawValue: entryTypeRawValue) ?? .declarative }
    var placements: [ModulePlacement] { placementsRawValue.moduleRawValues().compactMap(ModulePlacement.init(rawValue:)) }
    var capabilities: [ModuleCapability] { capabilitiesRawValue.moduleRawValues().compactMap(ModuleCapability.init(rawValue:)) }
    var containsForbiddenCapability: Bool { capabilities.contains { $0.isForbidden } }
    func supports(_ placement: ModulePlacement) -> Bool { placements.contains(placement) }
}

@Model
final class ModuleInstance {
    @Attribute(.unique) var id: UUID
    var moduleIdentifier: String
    var placementRawValue: String
    var configurationData: Data?
    var order: Int
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    init(id: UUID = UUID(), moduleIdentifier: String, placement: ModulePlacement, configurationData: Data? = nil, order: Int = 0, isEnabled: Bool = true, createdAt: Date = Date(), updatedAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.moduleIdentifier = moduleIdentifier
        placementRawValue = placement.rawValue
        self.configurationData = configurationData
        self.order = order
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

extension ModuleInstance {
    var placement: ModulePlacement {
        get { ModulePlacement(rawValue: placementRawValue) ?? .dashboardCompact }
        set { placementRawValue = newValue.rawValue }
    }
}

@Model
final class ModulePermissionGrant {
    @Attribute(.unique) var id: UUID
    var moduleIdentifier: String
    var capabilityRawValue: String
    var isGranted: Bool
    var grantedAt: Date?
    var revokedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), moduleIdentifier: String, capability: ModuleCapability, isGranted: Bool = false, grantedAt: Date? = nil, revokedAt: Date? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.moduleIdentifier = moduleIdentifier
        capabilityRawValue = capability.rawValue
        self.isGranted = isGranted
        self.grantedAt = grantedAt
        self.revokedAt = revokedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension ModulePermissionGrant {
    var capability: ModuleCapability {
        get { ModuleCapability(rawValue: capabilityRawValue) ?? .readProjects }
        set { capabilityRawValue = newValue.rawValue }
    }
}

enum ModuleComponentType: String, CaseIterable, Identifiable, Codable {
    case text, metric, progress, list, checklist, tagList, activityDots, compactChart, button, link, noteInput, dateInput, toggle, divider, sectionHeader
    var id: String { rawValue }
}

enum ModuleDeclarativeActionType: String, CaseIterable, Identifiable, Codable {
    case openDestination, createTask, createLog, createNote, createRoutine, createAdjustment, toggleValue, updateModuleField
    var id: String { rawValue }
}

struct ModuleComponentDefinition: Identifiable, Codable, Equatable {
    var id: UUID
    var typeRawValue: String
    var title: String
    var subtitle: String?
    var value: String
    var dataBindingId: UUID?
    var actionId: UUID?
    var actionRawValue: String?
    var styleRawValue: String?
    var order: Int?
    var configurationData: Data?
    var children: [ModuleComponentDefinition]

    init(
        id: UUID = UUID(),
        type: ModuleComponentType,
        title: String = "",
        subtitle: String? = nil,
        value: String = "",
        dataBindingId: UUID? = nil,
        actionId: UUID? = nil,
        action: ModuleDeclarativeActionType? = nil,
        styleRawValue: String? = nil,
        order: Int? = nil,
        configurationData: Data? = nil,
        children: [ModuleComponentDefinition] = []
    ) {
        self.id = id
        typeRawValue = type.rawValue
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.dataBindingId = dataBindingId
        self.actionId = actionId
        actionRawValue = action?.rawValue
        self.styleRawValue = styleRawValue
        self.order = order
        self.configurationData = configurationData
        self.children = children
    }
}

extension ModuleComponentDefinition {
    var type: ModuleComponentType? { ModuleComponentType(rawValue: typeRawValue) }
    var action: ModuleDeclarativeActionType? { actionRawValue.flatMap(ModuleDeclarativeActionType.init(rawValue:)) }
}

struct DeclarativeModuleConfiguration: Codable, Equatable {
    var components: [ModuleComponentDefinition]

    init(components: [ModuleComponentDefinition] = []) {
        self.components = components
    }
}

enum ModuleActionType: String, CaseIterable, Identifiable, Codable {
    case openProject, openPlan, openCalendar, openLog, createTask, createLog, createNote, createRoutine, createAdjustment, createWorkBlock, updateModuleField, exportModuleData
    var id: String { rawValue }
}

struct ModuleAction: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var typeRawValue: String
    var title: String
    var payload: [String: String]

    init(type: ModuleActionType, title: String = "", payload: [String: String] = [:]) {
        typeRawValue = type.rawValue
        self.title = title
        self.payload = payload
    }
}

extension ModuleAction {
    var type: ModuleActionType? { ModuleActionType(rawValue: typeRawValue) }
}

enum ModuleError: LocalizedError, Identifiable {
    case incompatibleVersion
    case invalidManifest(String)
    case permissionDenied(ModuleCapability)
    case renderingFailed(String)
    case actionFailed(String)

    var id: String { errorDescription ?? UUID().uuidString }

    var errorDescription: String? {
        switch self {
        case .incompatibleVersion: return "이 Module은 현재 nou ae 버전과 호환되지 않습니다."
        case .invalidManifest(let message): return "Module manifest가 올바르지 않습니다. \(message)"
        case .permissionDenied(let capability): return "\(capability.title) 권한이 필요합니다."
        case .renderingFailed(let message): return "Module 렌더링에 실패했습니다. \(message)"
        case .actionFailed(let message): return "Module action에 실패했습니다. \(message)"
        }
    }
}

struct ModulePermissionStore {
    var grants: [ModulePermissionGrant]

    func isGranted(moduleIdentifier: String, capability: ModuleCapability) -> Bool {
        guard !capability.isForbidden else { return false }
        return grants.contains { $0.moduleIdentifier == moduleIdentifier && $0.capability == capability && $0.isGranted }
    }

    func hasRequiredCapabilities(for manifest: ModuleManifest) -> Bool {
        manifest.capabilities.allSatisfy { isGranted(moduleIdentifier: manifest.id, capability: $0) }
    }
}

struct ModuleContext {
    var moduleIdentifier: String
    var currentDate: Date
    var selectedAreaId: UUID?
    var selectedProjectId: UUID?
    var currentPlacement: ModulePlacement
    var projects: [Project]
    var tasks: [RawTask]
    var workBlocks: [WorkBlock]
    var logs: [ProjectLog]
    var routines: [Routine]
    var permissionStore: ModulePermissionStore
    var actionRouter: ModuleActionRouter?
}

private extension String {
    func moduleRawValues() -> [String] {
        split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}
