#if canImport(AppIntents)
import AppIntents
import Foundation

struct AreaEntity: AppEntity, Identifiable {
    var id: String
    var title: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Area"
    static let defaultQuery = AreaEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "Area")
    }
}

struct ProjectEntity: AppEntity, Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var isArchived: Bool

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Project"
    static let defaultQuery = ProjectEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
}

struct TaskEntity: AppEntity, Identifiable {
    var id: String
    var title: String
    var subtitle: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Task"
    static let defaultQuery = TaskEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
}

struct RoutineEntity: AppEntity, Identifiable {
    var id: String
    var title: String
    var subtitle: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Routine"
    static let defaultQuery = RoutineEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
}

struct WorkBlockEntity: AppEntity, Identifiable {
    var id: String
    var title: String
    var subtitle: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "WorkBlock"
    static let defaultQuery = WorkBlockEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
}

struct ShortcutModuleEntity: AppEntity, Identifiable {
    var id: String
    var title: String
    var subtitle: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Module"
    static let defaultQuery = ShortcutModuleEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
}

struct ShortcutModuleActionEntity: AppEntity, Identifiable {
    var id: String
    var moduleIdentifier: String
    var title: String
    var subtitle: String
    var actionIdentifier: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Module Action"
    static let defaultQuery = ShortcutModuleActionEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
}

struct AreaEntityQuery: EntityQuery {
    func entities(for identifiers: [AreaEntity.ID]) async throws -> [AreaEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.areaEntities() }
        return values.filter { identifiers.contains($0.id) }.map { AreaEntity(id: $0.id, title: $0.title) }
    }

    func suggestedEntities() async throws -> [AreaEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.areaEntities() }
        return values.map { AreaEntity(id: $0.id, title: $0.title) }
    }
}

struct ProjectEntityQuery: EntityQuery {
    func entities(for identifiers: [ProjectEntity.ID]) async throws -> [ProjectEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.projectEntities() }
        return values.filter { identifiers.contains($0.id) }.map { ProjectEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle, isArchived: $0.isArchived) }
    }

    func suggestedEntities() async throws -> [ProjectEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.projectEntities(includeCompleted: false) }
        return values.map { ProjectEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle, isArchived: $0.isArchived) }
    }
}

struct TaskEntityQuery: EntityQuery {
    func entities(for identifiers: [TaskEntity.ID]) async throws -> [TaskEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.taskEntities() }
        return values.filter { identifiers.contains($0.id) }.map { TaskEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
    }

    func suggestedEntities() async throws -> [TaskEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.taskEntities() }
        return values.map { TaskEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
    }
}

struct RoutineEntityQuery: EntityQuery {
    func entities(for identifiers: [RoutineEntity.ID]) async throws -> [RoutineEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.routineEntities() }
        return values.filter { identifiers.contains($0.id) }.map { RoutineEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
    }

    func suggestedEntities() async throws -> [RoutineEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.routineEntities() }
        return values.map { RoutineEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
    }
}

struct WorkBlockEntityQuery: EntityQuery {
    func entities(for identifiers: [WorkBlockEntity.ID]) async throws -> [WorkBlockEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.workBlockEntities() }
        return values.filter { identifiers.contains($0.id) }.map { WorkBlockEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
    }

    func suggestedEntities() async throws -> [WorkBlockEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.workBlockEntities() }
        return values.map { WorkBlockEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
    }
}

struct ShortcutModuleEntityQuery: EntityQuery {
    func entities(for identifiers: [ShortcutModuleEntity.ID]) async throws -> [ShortcutModuleEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.moduleEntities() }
        return values.filter { identifiers.contains($0.id) }.map { ShortcutModuleEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
    }

    func suggestedEntities() async throws -> [ShortcutModuleEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.moduleEntities() }
        return values.map { ShortcutModuleEntity(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
    }
}

struct ShortcutModuleActionEntityQuery: EntityQuery {
    func entities(for identifiers: [ShortcutModuleActionEntity.ID]) async throws -> [ShortcutModuleActionEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.moduleActionEntities() }
        return values.filter { identifiers.contains($0.id) }.map { ShortcutModuleActionEntity(id: $0.id, moduleIdentifier: $0.moduleIdentifier, title: $0.title, subtitle: $0.subtitle, actionIdentifier: $0.actionIdentifier) }
    }

    func suggestedEntities() async throws -> [ShortcutModuleActionEntity] {
        let values = try await MainActor.run { try IntentServiceContainer.shared.moduleActionEntities() }
        return values.map { ShortcutModuleActionEntity(id: $0.id, moduleIdentifier: $0.moduleIdentifier, title: $0.title, subtitle: $0.subtitle, actionIdentifier: $0.actionIdentifier) }
    }
}
#endif
