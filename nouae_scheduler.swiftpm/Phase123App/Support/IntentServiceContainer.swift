import Foundation
import SwiftData

enum NouAEIntentError: LocalizedError {
    case dataStoreUnavailable
    case entityNotFound
    case projectArchived
    case routineDisabled
    case routineAlreadyCompleted
    case permissionRequired
    case moduleDisabled
    case modulePermissionDenied
    case unsupportedAction
    case invalidInput
    case navigationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .dataStoreUnavailable: return "nou ae 데이터 저장소를 아직 사용할 수 없습니다."
        case .entityNotFound: return "선택한 항목을 찾을 수 없습니다."
        case .projectArchived: return "선택한 Project는 archived 상태입니다."
        case .routineDisabled: return "이 Routine은 비활성 상태입니다."
        case .routineAlreadyCompleted: return "오늘 이 Routine은 이미 완료되었습니다."
        case .permissionRequired: return "nou ae를 열어 Calendar 또는 Reminder 접근을 허용해주세요."
        case .moduleDisabled: return "이 Module은 비활성 상태입니다."
        case .modulePermissionDenied: return "이 Module에 필요한 권한이 허용되지 않았습니다."
        case .unsupportedAction: return "지원하지 않는 Shortcut Action입니다."
        case .invalidInput: return "입력값을 확인해주세요."
        case .navigationFailed: return "nou ae 화면을 열 수 없습니다."
        case .unknown: return "작업을 완료하지 못했습니다."
        }
    }
}

@MainActor
final class IntentServiceContainer {
    static let shared = IntentServiceContainer()

    private(set) var container: ModelContainer?
    private(set) var context: ModelContext?
    private(set) var stores: AppStores?
    private(set) var services: AppServices?
    private(set) var moduleActionRouter: ModuleActionRouter?

    private init() {}

    func configure(container: ModelContainer, stores: AppStores, services: AppServices) {
        self.container = container
        context = container.mainContext
        self.stores = stores
        self.services = services
        moduleActionRouter = services.moduleActionRouter
    }

    func requireContext() throws -> ModelContext {
        guard let context else { throw NouAEIntentError.dataStoreUnavailable }
        return context
    }

    func requireStores() throws -> AppStores {
        guard let stores else { throw NouAEIntentError.dataStoreUnavailable }
        return stores
    }

    func requireServices() throws -> AppServices {
        guard let services else { throw NouAEIntentError.dataStoreUnavailable }
        return services
    }

    func areaEntities() throws -> [AreaEntitySnapshot] {
        try requireContext().fetch(FetchDescriptor<ProjectArea>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
            .filter { $0.archivedAt == nil }
            .prefix(20)
            .map { AreaEntitySnapshot(area: $0) }
    }

    func projectEntities(includeCompleted: Bool = true) throws -> [ProjectEntitySnapshot] {
        let projects = try requireContext().fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
            .filter { $0.archivedAt == nil && $0.status != .archived && (includeCompleted || $0.status != .completed) }
        let areas = try requireContext().fetch(FetchDescriptor<ProjectArea>())
        return projects.prefix(20).map { project in
            ProjectEntitySnapshot(project: project, area: areas.first { $0.id == project.areaId })
        }
    }

    func taskEntities() throws -> [TaskEntitySnapshot] {
        let projects = try requireContext().fetch(FetchDescriptor<Project>())
        return try requireContext().fetch(FetchDescriptor<RawTask>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            .filter { !$0.isConvertedToBlock }
            .prefix(20)
            .map { TaskEntitySnapshot(task: $0, project: projects.first { $0.id == $0.projectId }) }
    }

    func routineEntities() throws -> [RoutineEntitySnapshot] {
        let routines = try requireStores().routineStore.routines
            .filter { $0.archivedAt == nil && $0.isActive }
            .prefix(20)
        return routines.map { RoutineEntitySnapshot(routine: $0) }
    }

    func workBlockEntities() throws -> [WorkBlockEntitySnapshot] {
        let projects = try requireContext().fetch(FetchDescriptor<Project>())
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return try requireContext().fetch(FetchDescriptor<WorkBlock>(sortBy: [SortDescriptor(\.startAt)]))
            .filter { $0.endAt >= start && $0.startAt <= end && $0.executionState != .stopped }
            .prefix(20)
            .map { WorkBlockEntitySnapshot(block: $0, project: projects.first { $0.id == $0.projectId }) }
    }

    func moduleEntities() throws -> [ShortcutModuleSnapshot] {
        let context = try requireContext()
        let registry = try requireStores().moduleRegistry
        let instances = try context.fetch(FetchDescriptor<ModuleInstance>()).filter { $0.archivedAt == nil && $0.isEnabled }
        return instances.compactMap { instance in
            guard let manifest = registry.module(for: instance.moduleIdentifier),
                  manifest.isShortcutEligible else { return nil }
            return ShortcutModuleSnapshot(manifest: manifest, placement: instance.placement)
        }
    }

    func moduleActionEntities(moduleIdentifier: String? = nil) throws -> [ShortcutModuleActionSnapshot] {
        try moduleEntities().flatMap { module in
            module.shortcutActionIdentifiers.map { actionId in
                ShortcutModuleActionSnapshot(module: module, actionIdentifier: actionId)
            }
        }
        .filter { moduleIdentifier == nil || $0.moduleIdentifier == moduleIdentifier }
        .prefix(20)
        .map { $0 }
    }
}

extension ModuleManifest {
    var isShortcutEligible: Bool {
        !containsForbiddenCapability && (capabilities.contains(.createTask) || capabilities.contains(.createLog) || capabilities.contains(.openProject) || capabilities.contains(.openPlan) || capabilities.contains(.openCalendar) || capabilities.contains(.openLog))
    }

    var shortcutDisplayName: String? { nil }

    var shortcutActionIdentifiers: [String] {
        var values: [String] = []
        if capabilities.contains(.createTask) { values.append(ModuleActionType.createTask.rawValue) }
        if capabilities.contains(.createLog) { values.append(ModuleActionType.createLog.rawValue) }
        if capabilities.contains(.openProject) { values.append(ModuleActionType.openProject.rawValue) }
        if capabilities.contains(.openPlan) { values.append(ModuleActionType.openPlan.rawValue) }
        if capabilities.contains(.openCalendar) { values.append(ModuleActionType.openCalendar.rawValue) }
        if capabilities.contains(.openLog) { values.append(ModuleActionType.openLog.rawValue) }
        return values
    }

    var shortcutRequiresForeground: Bool {
        shortcutActionIdentifiers.contains { value in
            value == ModuleActionType.openProject.rawValue ||
            value == ModuleActionType.openPlan.rawValue ||
            value == ModuleActionType.openCalendar.rawValue ||
            value == ModuleActionType.openLog.rawValue
        }
    }
}

struct AreaEntitySnapshot: Identifiable {
    let id: String
    let title: String

    init(area: ProjectArea) {
        id = area.id.uuidString
        title = area.title
    }
}

struct ProjectEntitySnapshot: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let isArchived: Bool

    init(project: Project, area: ProjectArea?) {
        id = project.id.uuidString
        title = project.title
        subtitle = "\(area?.title ?? "Unassigned") · \(project.status.title)"
        isArchived = project.status == .archived || project.archivedAt != nil
    }
}

struct TaskEntitySnapshot: Identifiable {
    let id: String
    let title: String
    let subtitle: String

    init(task: RawTask, project: Project?) {
        id = task.id.uuidString
        title = task.title
        subtitle = "\(project?.title ?? "BLOCK") · Todo"
    }
}

struct RoutineEntitySnapshot: Identifiable {
    let id: String
    let title: String
    let subtitle: String

    init(routine: Routine) {
        id = routine.id.uuidString
        title = routine.title
        subtitle = "\(routine.frequency.title) · \(routine.startMinuteOfDay / 60):\(String(format: "%02d", routine.startMinuteOfDay % 60))"
    }
}

struct WorkBlockEntitySnapshot: Identifiable {
    let id: String
    let title: String
    let subtitle: String

    init(block: WorkBlock, project: Project?) {
        id = block.id.uuidString
        title = block.title
        subtitle = "\(block.startAt.formatted(date: .omitted, time: .shortened))-\(block.endAt.formatted(date: .omitted, time: .shortened)) · \(project?.title ?? "BLOCK")"
    }
}

struct ShortcutModuleSnapshot: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let placement: ModulePlacement
    let shortcutActionIdentifiers: [String]

    init(manifest: ModuleManifest, placement: ModulePlacement) {
        id = manifest.id
        title = manifest.shortcutDisplayName ?? manifest.name
        subtitle = "\(placement.title) · \(manifest.author)"
        self.placement = placement
        shortcutActionIdentifiers = manifest.shortcutActionIdentifiers
    }
}

struct ShortcutModuleActionSnapshot: Identifiable {
    let id: String
    let moduleIdentifier: String
    let title: String
    let subtitle: String
    let actionIdentifier: String

    init(module: ShortcutModuleSnapshot, actionIdentifier: String) {
        id = "\(module.id):\(actionIdentifier)"
        moduleIdentifier = module.id
        title = actionIdentifier
        subtitle = module.title
        self.actionIdentifier = actionIdentifier
    }
}
