import Combine
import Foundation
import SwiftData
import SwiftUI

protocol NouAENativeModule {
    var manifest: ModuleManifest { get }
    func makeView(context: ModuleContext) -> AnyView
    func handle(action: ModuleAction, context: ModuleContext) async throws
}

struct NativeModuleWrapper {
    let manifest: ModuleManifest
    private let viewBuilder: (ModuleContext) -> AnyView
    private let actionHandler: (ModuleAction, ModuleContext) async throws -> Void

    init<M: NouAENativeModule>(_ module: M) {
        manifest = module.manifest
        viewBuilder = module.makeView
        actionHandler = module.handle
    }

    func makeView(context: ModuleContext) -> AnyView {
        viewBuilder(context)
    }

    func handle(action: ModuleAction, context: ModuleContext) async throws {
        try await actionHandler(action, context)
    }
}

struct ModuleRenderDescriptor: Identifiable {
    let instance: ModuleInstance
    let manifest: ModuleManifest
    var id: UUID { instance.id }
}

@MainActor
final class ModuleRegistry: ObservableObject {
    @Published private var nativeModules: [String: NativeModuleWrapper] = [:]
    @Published private var declarativeManifests: [String: ModuleManifest] = [:]

    private let storedManifestKey = "nouae.modules.declarativeManifests.v1"
    private let supportedSchemaVersion = 1

    init() {
        loadStoredManifests()
        registerBuiltInModule(WeeklyRoutineSummaryModule())
        registerBuiltInModule(ProjectReviewShortcutModule())
    }

    var allManifests: [ModuleManifest] {
        Array(nativeModules.values.map(\.manifest) + Array(declarativeManifests.values))
            .sorted { $0.name < $1.name }
    }

    func registerBuiltInModule<M: NouAENativeModule>(_ module: M) {
        let wrapper = NativeModuleWrapper(module)
        guard nativeModules[wrapper.manifest.id] == nil else { return }
        nativeModules[wrapper.manifest.id] = wrapper
    }

    func registerManifest(_ manifest: ModuleManifest) throws {
        try validateManifest(manifest)
        guard nativeModules[manifest.id] == nil else {
            throw ModuleError.invalidManifest("Built-in Module id와 중복됩니다.")
        }
        declarativeManifests[manifest.id] = manifest
        saveStoredManifests()
    }

    func nativeModule(for identifier: String) -> NativeModuleWrapper? {
        nativeModules[identifier]
    }

    func module(for identifier: String) -> ModuleManifest? {
        nativeModules[identifier]?.manifest ?? declarativeManifests[identifier]
    }

    func enabledModules(for placement: ModulePlacement, instances: [ModuleInstance]) -> [ModuleRenderDescriptor] {
        instances
            .filter { $0.archivedAt == nil && $0.isEnabled && $0.placement == placement }
            .compactMap { instance in
                guard let manifest = module(for: instance.moduleIdentifier), manifest.supports(placement) else { return nil }
                return ModuleRenderDescriptor(instance: instance, manifest: manifest)
            }
            .sorted { lhs, rhs in
                if lhs.instance.order == rhs.instance.order {
                    return lhs.manifest.name < rhs.manifest.name
                }
                return lhs.instance.order < rhs.instance.order
            }
    }

    func validateManifest(_ manifest: ModuleManifest) throws {
        guard !manifest.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ModuleError.invalidManifest("id가 비어 있습니다.")
        }
        guard !manifest.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ModuleError.invalidManifest("name이 비어 있습니다.")
        }
        guard manifest.schemaVersion == supportedSchemaVersion else {
            throw ModuleError.incompatibleVersion
        }
        guard !manifest.placements.isEmpty else {
            throw ModuleError.invalidManifest("placement가 없습니다.")
        }
        guard !manifest.containsForbiddenCapability else {
            throw ModuleError.invalidManifest("금지 Capability가 포함되어 있습니다.")
        }
    }

    func installBuiltInDefaults(context: ModelContext) throws {
        let instances = try context.fetch(FetchDescriptor<ModuleInstance>())
        for manifest in nativeModules.values.map(\.manifest).filter(\.isEnabledByDefault) {
            for placement in manifest.placements where !instances.contains(where: { $0.moduleIdentifier == manifest.id && $0.placement == placement && $0.archivedAt == nil }) {
                let order = instances.filter { $0.placement == placement && $0.archivedAt == nil }.count
                context.insert(ModuleInstance(moduleIdentifier: manifest.id, placement: placement, order: order, isEnabled: true))
            }
            try ensurePermissionGrants(for: manifest, isGranted: true, context: context)
        }
        try context.save()
    }

    @discardableResult
    func installModule(_ manifest: ModuleManifest, placement: ModulePlacement, context: ModelContext) throws -> ModuleInstance {
        try validateManifest(manifest)
        if manifest.entryType == .declarative {
            try registerManifest(manifest)
        }
        guard manifest.supports(placement) else {
            throw ModuleError.invalidManifest("지원하지 않는 placement입니다.")
        }

        let instances = try context.fetch(FetchDescriptor<ModuleInstance>())
        let order = instances.filter { $0.placement == placement && $0.archivedAt == nil }.count
        let instance = ModuleInstance(moduleIdentifier: manifest.id, placement: placement, order: order, isEnabled: true)
        context.insert(instance)
        try ensurePermissionGrants(for: manifest, isGranted: manifest.origin == .builtIn, context: context)
        try context.save()
        return instance
    }

    func archiveModuleInstance(_ instance: ModuleInstance) {
        instance.archivedAt = Date()
        instance.isEnabled = false
        instance.updatedAt = Date()
    }

    private func ensurePermissionGrants(for manifest: ModuleManifest, isGranted: Bool, context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<ModulePermissionGrant>())
        for capability in manifest.capabilities where !capability.isForbidden {
            if !existing.contains(where: { $0.moduleIdentifier == manifest.id && $0.capability == capability }) {
                context.insert(ModulePermissionGrant(moduleIdentifier: manifest.id, capability: capability, isGranted: isGranted, grantedAt: isGranted ? Date() : nil))
            }
        }
    }

    private func loadStoredManifests() {
        guard let data = UserDefaults.standard.data(forKey: storedManifestKey),
              let values = try? JSONDecoder().decode([ModuleManifest].self, from: data) else { return }
        declarativeManifests = Dictionary(uniqueKeysWithValues: values.map { ($0.id, $0) })
    }

    private func saveStoredManifests() {
        guard let data = try? JSONEncoder().encode(Array(declarativeManifests.values)) else { return }
        UserDefaults.standard.set(data, forKey: storedManifestKey)
    }
}

@MainActor
final class ModuleActionRouter {
    private let stores: AppStores

    init(stores: AppStores) {
        self.stores = stores
    }

    func handle(_ action: ModuleAction, context: ModuleContext) async throws {
        guard let type = action.type else {
            throw ModuleError.actionFailed("알 수 없는 action입니다.")
        }

        switch type {
        case .createTask:
            try require(.createTask, context: context)
            let title = action.payload["title"] ?? action.title
            _ = try stores.rawTaskStore.createRawTask(title: title)
        case .createLog:
            try require(.createLog, context: context)
            let content = action.payload["content"] ?? action.title
            try stores.logStore.createLog(logType: .project, areaId: context.selectedAreaId, projectId: context.selectedProjectId, workBlockId: nil, title: action.title, focusLevel: nil, moodTags: [], blockerTags: [], blockerNote: "", nextAdjustment: action.payload["nextAdjustment"] ?? "", content: content)
        case .openProject, .openPlan, .openCalendar, .openLog:
            throw ModuleError.actionFailed("Navigation routing은 다음 단계에서 AppRouter에 연결합니다.")
        case .createNote, .createRoutine, .createAdjustment, .createWorkBlock, .updateModuleField, .exportModuleData:
            throw ModuleError.actionFailed("이 action은 L22 foundation에서 아직 실행하지 않습니다.")
        }
    }

    private func require(_ capability: ModuleCapability, context: ModuleContext) throws {
        guard context.permissionStore.isGranted(moduleIdentifier: context.moduleIdentifier, capability: capability) else {
            throw ModuleError.permissionDenied(capability)
        }
    }
}

enum ModuleImportValidator {
    private static let maxBytes = 256_000
    private static let blockedTokens = ["<script", "javascript:", "executeCode", "directEventKitAccess", "directPhotoLibraryAccess", "arbitraryFileAccess", "networkRequest"]

    static func validate(data: Data) throws -> ModuleManifest {
        guard data.count <= maxBytes else { throw ModuleError.invalidManifest("파일이 너무 큽니다.") }
        guard let text = String(data: data, encoding: .utf8) else { throw ModuleError.invalidManifest("UTF-8 JSON만 지원합니다.") }
        for token in blockedTokens where text.localizedCaseInsensitiveContains(token) {
            throw ModuleError.invalidManifest("실행 코드 또는 금지 Capability가 포함되어 있습니다.")
        }

        let decoder = JSONDecoder()
        if let payload = try? decoder.decode(ModulePackPayload.self, from: data) {
            try validateComponents(payload.components)
            return payload.manifest
        }
        if let manifest = try? decoder.decode(ModuleManifest.self, from: data) {
            return manifest
        }
        throw ModuleError.invalidManifest("ModuleManifest를 읽을 수 없습니다.")
    }

    private static func validateComponents(_ components: [ModuleComponentDefinition], depth: Int = 0) throws {
        guard depth <= 3 else { throw ModuleError.invalidManifest("component depth가 너무 깊습니다.") }
        guard components.count <= 40 else { throw ModuleError.invalidManifest("component 수가 너무 많습니다.") }
        for component in components {
            guard component.type != nil else { throw ModuleError.invalidManifest("지원하지 않는 component가 있습니다.") }
            try validateComponents(component.children, depth: depth + 1)
        }
    }
}

private struct ModulePackPayload: Codable {
    var manifest: ModuleManifest
    var components: [ModuleComponentDefinition]
}
