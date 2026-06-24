import Foundation
import SwiftData

enum ModuleBuilderTemplate: String, CaseIterable, Identifiable, Codable {
    case blank
    case metricCard
    case listCard
    case progressCard
    case quickAction
    case logPreset
    case routineTemplate
    case projectSummary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blank: return "Blank"
        case .metricCard: return "Metric Card"
        case .listCard: return "List Card"
        case .progressCard: return "Progress Card"
        case .quickAction: return "Quick Action"
        case .logPreset: return "Log Preset"
        case .routineTemplate: return "Routine Template"
        case .projectSummary: return "Project Summary"
        }
    }
}

enum ModuleBuilderStep: String, CaseIterable, Identifiable, Codable {
    case purpose = "Purpose"
    case placement = "Placement"
    case template = "Template"
    case data = "Data"
    case components = "Components"
    case actions = "Actions"
    case permissions = "Permissions"
    case preview = "Preview"

    var id: String { rawValue }
}

enum ModuleBuilderDraftState: String {
    case unsaved = "Unsaved"
    case saved = "Saved"
    case invalid = "Invalid"
    case ready = "Ready"
}

enum ModuleDataSourceKind: String, CaseIterable, Identifiable, Codable {
    case areas
    case projects
    case tasks
    case workBlocks
    case logs
    case projectNotes
    case routines
    case routineOccurrences
    case nextAdjustments
    case trackerSummary
    case currentProject
    case currentArea
    case currentDate
    case staticData

    var id: String { rawValue }

    var title: String {
        switch self {
        case .areas: return "Areas"
        case .projects: return "Projects"
        case .tasks: return "Tasks"
        case .workBlocks: return "WorkBlocks"
        case .logs: return "Logs"
        case .projectNotes: return "Project Notes"
        case .routines: return "Routines"
        case .routineOccurrences: return "Routine Occurrences"
        case .nextAdjustments: return "Next Adjustments"
        case .trackerSummary: return "Tracker Summary"
        case .currentProject: return "Current Project"
        case .currentArea: return "Current Area"
        case .currentDate: return "Current Date"
        case .staticData: return "Static Data"
        }
    }
}

enum ModuleDataScope: String, CaseIterable, Identifiable, Codable {
    case global
    case currentProject
    case selectedProject
    case currentArea
    case selectedArea

    var id: String { rawValue }
}

enum ModuleDataAggregation: String, CaseIterable, Identifiable, Codable {
    case count
    case sumDuration
    case completionRate
    case latest
    case average
    case list
    case streak

    var id: String { rawValue }
}

enum ModuleDataDateRange: String, CaseIterable, Identifiable, Codable {
    case today
    case thisWeek
    case last7Days
    case thisMonth
    case last30Days

    var id: String { rawValue }
}

enum ModuleActionBuilderType: String, CaseIterable, Identifiable, Codable {
    case openDashboard
    case openCalendar
    case openProjects
    case openProject
    case openPlan
    case openLog
    case openRoutine
    case openProjectNotes
    case openProjectPage
    case createTask
    case createLog
    case createNote
    case createRoutine
    case createAdjustment
    case markTaskTodo
    case markTaskDoing
    case markTaskDone
    case completeReview
    case enableRoutine
    case disableRoutine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openDashboard: return "Open Dashboard"
        case .openCalendar: return "Open Calendar"
        case .openProjects: return "Open Projects"
        case .openProject: return "Open Project"
        case .openPlan: return "Open Plan"
        case .openLog: return "Open Log"
        case .openRoutine: return "Open Routine"
        case .openProjectNotes: return "Open Project Notes"
        case .openProjectPage: return "Open Project Page"
        case .createTask: return "Create Task"
        case .createLog: return "Create Log"
        case .createNote: return "Create Note"
        case .createRoutine: return "Create Routine"
        case .createAdjustment: return "Create Adjustment"
        case .markTaskTodo: return "Mark Task Todo"
        case .markTaskDoing: return "Mark Task Doing"
        case .markTaskDone: return "Mark Task Done"
        case .completeReview: return "Complete Review"
        case .enableRoutine: return "Enable Routine"
        case .disableRoutine: return "Disable Routine"
        }
    }

    var declarativeAction: ModuleDeclarativeActionType? {
        switch self {
        case .createTask: return .createTask
        case .createLog: return .createLog
        case .createNote: return .createNote
        case .createRoutine: return .createRoutine
        case .createAdjustment: return .createAdjustment
        case .openDashboard, .openCalendar, .openProjects, .openProject, .openPlan, .openLog, .openRoutine, .openProjectNotes, .openProjectPage:
            return .openDestination
        case .markTaskTodo, .markTaskDoing, .markTaskDone, .completeReview, .enableRoutine, .disableRoutine:
            return .updateModuleField
        }
    }
}

struct ModuleDataBinding: Identifiable, Codable, Equatable {
    var id: UUID
    var sourceRawValue: String
    var scopeRawValue: String
    var fieldRawValue: String
    var aggregationRawValue: String?
    var filterData: Data?
    var dateRangeRawValue: String?
    var sortRawValue: String?
    var limit: Int?
    var projectScopeRawValue: String?

    init(
        id: UUID = UUID(),
        source: ModuleDataSourceKind = .staticData,
        scope: ModuleDataScope = .global,
        fieldRawValue: String = "count",
        aggregation: ModuleDataAggregation? = nil,
        dateRange: ModuleDataDateRange? = nil,
        sortRawValue: String? = nil,
        limit: Int? = nil,
        projectScopeRawValue: String? = nil,
        filterData: Data? = nil
    ) {
        self.id = id
        sourceRawValue = source.rawValue
        scopeRawValue = scope.rawValue
        self.fieldRawValue = fieldRawValue
        aggregationRawValue = aggregation?.rawValue
        dateRangeRawValue = dateRange?.rawValue
        self.sortRawValue = sortRawValue
        self.limit = limit
        self.projectScopeRawValue = projectScopeRawValue
        self.filterData = filterData
    }
}

extension ModuleDataBinding {
    var source: ModuleDataSourceKind { ModuleDataSourceKind(rawValue: sourceRawValue) ?? .staticData }
    var scope: ModuleDataScope { ModuleDataScope(rawValue: scopeRawValue) ?? .global }
    var aggregation: ModuleDataAggregation? { aggregationRawValue.flatMap(ModuleDataAggregation.init(rawValue:)) }
    var dateRange: ModuleDataDateRange? { dateRangeRawValue.flatMap(ModuleDataDateRange.init(rawValue:)) }
}

struct ModuleActionDefinition: Identifiable, Codable, Equatable {
    var id: UUID
    var actionTypeRawValue: String
    var label: String
    var iconSystemName: String?
    var parametersData: Data?
    var requiresConfirmation: Bool
    var order: Int

    init(
        id: UUID = UUID(),
        actionType: ModuleActionBuilderType = .openPlan,
        label: String = "Open Plan",
        iconSystemName: String? = "arrow.right",
        parametersData: Data? = nil,
        requiresConfirmation: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        actionTypeRawValue = actionType.rawValue
        self.label = label
        self.iconSystemName = iconSystemName
        self.parametersData = parametersData
        self.requiresConfirmation = requiresConfirmation
        self.order = order
    }
}

extension ModuleActionDefinition {
    var actionType: ModuleActionBuilderType { ModuleActionBuilderType(rawValue: actionTypeRawValue) ?? .openPlan }
}

struct ModuleCapabilityRequest: Identifiable, Codable, Equatable {
    var id: String { capability.rawValue }
    var capability: ModuleCapability
    var isRequired: Bool
    var reason: String
}

struct ModuleValidationResult: Codable, Equatable {
    var errors: [String]
    var warnings: [String]
    var requestedCapabilities: [ModuleCapabilityRequest]

    var isInstallable: Bool { errors.isEmpty }
}

struct ModuleBuilderExportPayload: Codable, Equatable {
    var manifest: ModuleManifest
    var components: [ModuleComponentDefinition]
    var dataBindings: [ModuleDataBinding]
    var actions: [ModuleActionDefinition]
    var requestedCapabilities: [ModuleCapability]
    var exportedAt: Date

    init(draft: ModuleBuilderDraft) {
        manifest = draft.manifest()
        components = draft.componentDefinitions.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
        dataBindings = draft.dataBindings
        actions = draft.actionDefinitions.sorted { $0.order < $1.order }
        requestedCapabilities = draft.requestedCapabilities
        exportedAt = Date()
    }
}

struct ModuleBuilderDraft: Identifiable, Codable, Equatable {
    var id: UUID
    var moduleIdentifier: String
    var name: String
    var descriptionText: String
    var categoryRawValue: String
    var iconSystemName: String
    var placementRawValue: String
    var templateRawValue: String
    var componentDefinitions: [ModuleComponentDefinition]
    var dataBindings: [ModuleDataBinding]
    var actionDefinitions: [ModuleActionDefinition]
    var requestedCapabilitiesRawValue: String
    var version: String
    var createdAt: Date
    var updatedAt: Date
    var lastValidatedAt: Date?

    init(
        id: UUID = UUID(),
        moduleIdentifier: String = "user.module.\(UUID().uuidString)",
        name: String = "",
        descriptionText: String = "",
        category: ModuleCategory = .utility,
        iconSystemName: String = "square.grid.2x2",
        placement: ModulePlacement = .dashboardCompact,
        template: ModuleBuilderTemplate = .blank,
        componentDefinitions: [ModuleComponentDefinition] = [],
        dataBindings: [ModuleDataBinding] = [],
        actionDefinitions: [ModuleActionDefinition] = [],
        requestedCapabilities: [ModuleCapability] = [],
        version: String = "1.0.0",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastValidatedAt: Date? = nil
    ) {
        self.id = id
        self.moduleIdentifier = moduleIdentifier
        self.name = name
        self.descriptionText = descriptionText
        categoryRawValue = category.rawValue
        self.iconSystemName = iconSystemName
        placementRawValue = placement.rawValue
        templateRawValue = template.rawValue
        self.componentDefinitions = componentDefinitions
        self.dataBindings = dataBindings
        self.actionDefinitions = actionDefinitions
        requestedCapabilitiesRawValue = requestedCapabilities.map(\.rawValue).joined(separator: ",")
        self.version = version
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastValidatedAt = lastValidatedAt
    }
}

extension ModuleBuilderDraft {
    var category: ModuleCategory {
        get { ModuleCategory(rawValue: categoryRawValue) ?? .utility }
        set { categoryRawValue = newValue.rawValue }
    }

    var placement: ModulePlacement {
        get { ModulePlacement(rawValue: placementRawValue) ?? .dashboardCompact }
        set { placementRawValue = newValue.rawValue }
    }

    var template: ModuleBuilderTemplate {
        get { ModuleBuilderTemplate(rawValue: templateRawValue) ?? .blank }
        set { templateRawValue = newValue.rawValue }
    }

    var requestedCapabilities: [ModuleCapability] {
        requestedCapabilitiesRawValue
            .split(separator: ",")
            .compactMap { ModuleCapability(rawValue: String($0)) }
    }

    mutating func setRequestedCapabilities(_ capabilities: [ModuleCapability]) {
        requestedCapabilitiesRawValue = capabilities.map(\.rawValue).joined(separator: ",")
    }

    func manifest() -> ModuleManifest {
        ModuleManifest(
            id: moduleIdentifier,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            descriptionText: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            version: version,
            author: "Local User",
            category: category,
            iconSystemName: iconSystemName.isEmpty ? "square.grid.2x2" : iconSystemName,
            origin: .user,
            placements: [placement],
            capabilities: requestedCapabilities,
            entryType: .declarative,
            isEnabledByDefault: false
        )
    }

    func configurationData() throws -> Data {
        try JSONEncoder().encode(DeclarativeModuleConfiguration(components: componentDefinitions.sorted { ($0.order ?? 0) < ($1.order ?? 0) }))
    }
}

@Model
final class ModuleDraftRecord {
    @Attribute(.unique) var id: UUID
    var draftData: Data
    var name: String
    var updatedAt: Date
    var createdAt: Date
    var archivedAt: Date?

    init(id: UUID = UUID(), draftData: Data, name: String, updatedAt: Date = Date(), createdAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.draftData = draftData
        self.name = name
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}

extension ModuleDraftRecord {
    var draft: ModuleBuilderDraft? {
        try? JSONDecoder().decode(ModuleBuilderDraft.self, from: draftData)
    }
}
