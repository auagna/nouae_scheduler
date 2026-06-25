import CryptoKit
import Foundation
import SwiftData

enum AppVersionProvider {
    static let currentVersion = "1.0.0"
    static let currentBuild = "48"
    static let supportedModuleSchemaVersion = 1
    static let supportedPackSchemaVersion = 1

    static func supports(minimumVersion: String) -> Bool {
        guard let required = SemanticVersion(minimumVersion),
              let current = SemanticVersion(currentVersion) else {
            return true
        }
        return current >= required
    }
}

enum TrustedPublisherRegistry {
    static var builtInPublishers: [TrustedPublisher] {
        [
            TrustedPublisher(
                publisherId: "com.nouae",
                publisherName: "nou ae",
                publicKeyData: Data(),
                algorithmRawValue: "Curve25519.Signing",
                addedAt: Date(),
                revokedAt: nil
            )
        ]
    }

    static func publisher(for id: String) -> TrustedPublisher? {
        builtInPublishers.first { $0.publisherId == id }
    }

    static func isTrustedPublisher(id: String) -> Bool {
        publisher(for: id)?.revokedAt == nil
    }

    static func isRevokedPublisher(id: String) -> Bool {
        publisher(for: id)?.revokedAt != nil
    }
}

enum ModulePackHashing {
    static func canonicalData<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func sha256Hex<T: Encodable>(_ value: T) throws -> String {
        try sha256Hex(canonicalData(value))
    }

    static func expectedIntegrity(for file: ModulePackFile) throws -> ModulePackIntegrity {
        let manifestHash = try sha256Hex(file.pack)
        let modulesHash = try sha256Hex(file.modules)
        let assetsHash = file.assets.isEmpty ? nil : try sha256Hex(file.assets)
        let payload = ModulePackIntegrityPayload(pack: file.pack, modules: file.modules, assets: file.assets)
        let fullHash = try sha256Hex(payload)
        return ModulePackIntegrity(manifestHash: manifestHash, modulesHash: modulesHash, assetsHash: assetsHash, fullPayloadHash: fullHash)
    }
}

private struct ModulePackIntegrityPayload: Codable {
    var pack: ModulePackManifest
    var modules: [ModulePackModuleDefinition]
    var assets: [ModulePackAsset]
}

enum ModulePackSignatureVerifier {
    static func trustState(for file: ModulePackFile) throws -> ModulePackTrustState {
        guard let signature = file.signature else {
            return .unverified
        }

        guard let publisher = TrustedPublisherRegistry.publisher(for: signature.publisherId) else {
            return .invalid
        }

        if publisher.revokedAt != nil {
            return .revoked
        }

        guard !publisher.publicKeyData.isEmpty else {
            return .unverified
        }

        let payload = ModulePackIntegrityPayload(pack: file.pack, modules: file.modules, assets: file.assets)
        let canonicalData = try ModulePackHashing.canonicalData(payload)
        guard let signatureData = Data(base64Encoded: signature.signatureBase64) else {
            return .invalid
        }

        switch signature.algorithm {
        case "Curve25519.Signing":
            let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publisher.publicKeyData)
            return publicKey.isValidSignature(signatureData, for: canonicalData) ? .verified : .invalid
        case "P256.Signing":
            let publicKey = try P256.Signing.PublicKey(x963Representation: publisher.publicKeyData)
            let ecdsaSignature = try P256.Signing.ECDSASignature(derRepresentation: signatureData)
            return publicKey.isValidSignature(ecdsaSignature, for: canonicalData) ? .verified : .invalid
        default:
            return .invalid
        }
    }
}

@MainActor
final class ModulePackStore {
    private let context: ModelContext
    private let validator: ModulePackImportValidator
    private let installer: ModulePackInstaller

    init(context: ModelContext) {
        self.context = context
        validator = ModulePackImportValidator(context: context)
        installer = ModulePackInstaller(context: context)
    }

    func validate(data: Data, registry: ModuleRegistry) -> ModulePackValidationResult {
        validator.validate(data: data, registry: registry)
    }

    func install(_ result: ModulePackValidationResult, registry: ModuleRegistry, approvedCapabilities: Set<ModuleCapability>) throws {
        try installer.installPack(result, registry: registry, approvedCapabilities: approvedCapabilities)
    }

    func disable(_ record: ModulePackRecord) throws {
        try installer.disablePack(record)
    }

    func enable(_ record: ModulePackRecord) throws {
        try installer.enablePack(record)
    }

    func uninstall(_ record: ModulePackRecord) throws {
        try installer.uninstallPack(record)
    }

    func rollback(_ record: ModulePackRecord, registry: ModuleRegistry) throws {
        try installer.rollbackPack(record, registry: registry)
    }
}

@MainActor
struct ModulePackImportValidator {
    private let context: ModelContext
    private let maxBytes = 5_000_000
    private let maxAssets = 20
    private let maxAssetBytes = 1_000_000
    private let blockedTokens = ["<script", "javascript:", "executeCode", "directEventKitAccess", "directPhotoLibraryAccess", "arbitraryFileAccess", "networkRequest", "shell", "python", "swift source"]

    init(context: ModelContext) {
        self.context = context
    }

    func validate(data: Data, registry: ModuleRegistry) -> ModulePackValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        var requestedCapabilities = Set<ModuleCapability>()
        var trustState: ModulePackTrustState = .unverified
        var packFile: ModulePackFile?
        var moduleDiff = ModulePackDiff.empty

        do {
            guard data.count <= maxBytes else { throw ModulePackError.fileTooLarge }
            guard let text = String(data: data, encoding: .utf8) else { throw ModulePackError.invalidFile("Pack must be UTF-8 JSON.") }
            for token in blockedTokens where text.localizedCaseInsensitiveContains(token) {
                throw ModulePackError.invalidFile("Pack contains blocked executable content marker: \(token)")
            }

            let decoded = try JSONDecoder().decode(ModulePackFile.self, from: data)
            packFile = decoded

            try validatePack(decoded)
            try validateAssets(decoded.assets)
            try validateIntegrity(decoded)
            if decoded.integrity == nil {
                warnings.append("This pack does not include an integrity block. Treat it as a local unverified pack.")
            }
            trustState = try ModulePackSignatureVerifier.trustState(for: decoded)
            if trustState == .invalid { throw ModulePackError.invalidSignature }
            if trustState == .revoked { throw ModulePackError.revokedPublisher }

            for module in decoded.modules {
                try registry.validateManifest(module.manifest)
                try validateComponents(module.components)
                requestedCapabilities.formUnion(module.manifest.capabilities.filter { !$0.isForbidden })
            }

            if trustState == .unverified {
                warnings.append("This is an unsigned local pack. Review permissions before installing.")
                if decoded.modules.contains(where: { $0.manifest.placements.contains(.settingsSection) }) {
                    throw ModulePackError.invalidModule("Unsigned packs cannot install Settings modules.")
                }
                requestedCapabilities = requestedCapabilities.filter { allowedForUnverified($0) }
            }

            moduleDiff = diff(for: decoded)
        } catch {
            errors.append(error.localizedDescription)
            trustState = .invalid
        }

        let requests = requestedCapabilities.sorted { $0.rawValue < $1.rawValue }.map {
            ModuleCapabilityRequest(capability: $0, isRequired: true, reason: "Requested by one or more modules in this pack.")
        }

        return ModulePackValidationResult(
            packFile: packFile,
            errors: errors,
            warnings: warnings,
            trustState: trustState,
            requestedCapabilities: requests,
            moduleDiff: moduleDiff
        )
    }

    private func validatePack(_ file: ModulePackFile) throws {
        guard file.pack.schemaVersion == AppVersionProvider.supportedPackSchemaVersion else { throw ModulePackError.unsupportedSchema }
        guard AppVersionProvider.supports(minimumVersion: file.pack.minimumAppVersion) else { throw ModulePackError.incompatibleAppVersion }
        guard !file.pack.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ModulePackError.invalidFile("Pack id is empty.") }
        guard !file.pack.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ModulePackError.invalidFile("Pack name is empty.") }

        let identifiers = file.modules.map(\.manifest.id)
        guard Set(identifiers).count == identifiers.count else { throw ModulePackError.duplicateModuleIdentifier }
        guard Set(file.pack.moduleIdentifiers) == Set(identifiers) else { throw ModulePackError.invalidFile("Pack moduleIdentifiers do not match included modules.") }

        for dependency in file.pack.dependencyIdentifiers where !identifiers.contains(dependency) {
            throw ModulePackError.dependencyMissing(dependency)
        }
    }

    private func validateIntegrity(_ file: ModulePackFile) throws {
        guard let integrity = file.integrity else {
            return
        }
        let expected = try ModulePackHashing.expectedIntegrity(for: file)
        guard integrity.algorithm == "SHA256",
              integrity.manifestHash == expected.manifestHash,
              integrity.modulesHash == expected.modulesHash,
              integrity.assetsHash == expected.assetsHash,
              integrity.fullPayloadHash == expected.fullPayloadHash else {
            throw ModulePackError.invalidIntegrity
        }
    }

    private func validateAssets(_ assets: [ModulePackAsset]) throws {
        guard assets.count <= maxAssets else { throw ModulePackError.invalidFile("Too many assets.") }
        let allowedTypes = ["image/png", "image/jpeg", "image/heic", "application/json", "text/markdown", "text/plain"]
        for asset in assets {
            guard allowedTypes.contains(asset.mimeType) else { throw ModulePackError.invalidFile("Unsupported asset type: \(asset.mimeType)") }
            guard asset.byteCount <= maxAssetBytes else { throw ModulePackError.invalidFile("Asset is larger than 1MB: \(asset.name)") }
            if let assetData = Data(base64Encoded: asset.base64Data), let checksum = asset.checksum {
                guard ModulePackHashing.sha256Hex(assetData) == checksum else { throw ModulePackError.invalidIntegrity }
            }
        }
    }

    private func validateComponents(_ components: [ModuleComponentDefinition], depth: Int = 0) throws {
        guard depth <= 1 else { throw ModulePackError.invalidModule("Nested modules or deep component trees are not allowed.") }
        guard components.count <= 8 else { throw ModulePackError.invalidModule("A module can contain up to 8 components.") }
        for component in components {
            guard component.type != nil else { throw ModulePackError.invalidModule("Unsupported component type.") }
            try validateComponents(component.children, depth: depth + 1)
        }
    }

    private func allowedForUnverified(_ capability: ModuleCapability) -> Bool {
        switch capability {
        case .exportModuleData, .updateTask, .directEventKitAccess, .directPhotoLibraryAccess, .arbitraryFileAccess, .executeCode, .networkRequest:
            return false
        default:
            return !capability.isForbidden
        }
    }

    private func diff(for file: ModulePackFile) -> ModulePackDiff {
        let existingRecords = (try? context.fetch(FetchDescriptor<ModulePackRecord>())) ?? []
        guard let existing = existingRecords.first(where: { $0.packIdentifier == file.pack.id && $0.archivedAt == nil }),
              let previousFile = existing.packFile else {
            return ModulePackDiff(added: file.modules.map(\.manifest.id), removed: [], updated: [], unchanged: [])
        }

        let currentIds = Set(previousFile.modules.map(\.manifest.id))
        let incomingIds = Set(file.modules.map(\.manifest.id))
        let added = incomingIds.subtracting(currentIds).sorted()
        let removed = currentIds.subtracting(incomingIds).sorted()
        var updated: [String] = []
        var unchanged: [String] = []

        for module in file.modules where currentIds.contains(module.manifest.id) {
            let oldVersion = previousFile.modules.first { $0.manifest.id == module.manifest.id }?.manifest.version
            if oldVersion == module.manifest.version {
                unchanged.append(module.manifest.id)
            } else {
                updated.append(module.manifest.id)
            }
        }

        return ModulePackDiff(added: added, removed: removed, updated: updated.sorted(), unchanged: unchanged.sorted())
    }
}

@MainActor
struct ModulePackInstaller {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func installPack(_ result: ModulePackValidationResult, registry: ModuleRegistry, approvedCapabilities: Set<ModuleCapability>) throws {
        guard result.isInstallable, let file = result.packFile else {
            throw ModulePackError.installFailed(result.errors.joined(separator: "\n"))
        }

        let required = Set(result.requestedCapabilities.filter(\.isRequired).map(\.capability))
        guard required.isSubset(of: approvedCapabilities) else {
            throw ModulePackError.permissionRequired
        }

        let records = try context.fetch(FetchDescriptor<ModulePackRecord>())
        let existing = records.first { $0.packIdentifier == file.pack.id && $0.archivedAt == nil }
        if let existingVersion = existing?.installedVersion,
           let old = SemanticVersion(existingVersion),
           let new = SemanticVersion(file.pack.version),
           new < old {
            throw ModulePackError.updateFailed("Older pack versions cannot overwrite the installed version. Use rollback instead.")
        }

        if let existing, !ModulePackConfigurationMigrator.canMigrate(from: existing.installedVersion, to: file.pack.version) {
            existing.installState = .needsReconfiguration
            existing.lastErrorMessage = "Major version update requires reconfiguration."
            existing.updatedAt = Date()
            try context.save()
            throw ModulePackError.migrationFailed("Major version update requires reconfiguration.")
        }

        let encodedFile = try JSONEncoder().encode(file)
        if let existing {
            let previousPackManifest = existing.packFile?.pack
            existing.previousVersionData = existing.manifestData
            existing.previousManifestData = previousPackManifest.flatMap { try? JSONEncoder().encode($0) }
            existing.manifestData = encodedFile
            existing.name = file.pack.name
            existing.installedVersion = file.pack.version
            existing.publisherId = file.pack.publisherId
            existing.publisherName = file.pack.publisherName
            existing.trustState = result.trustState
            existing.installState = .installed
            existing.disabledAt = nil
            existing.updatedAt = Date()
            existing.lastValidationAt = Date()
            existing.lastErrorMessage = nil
        } else {
            context.insert(ModulePackRecord(
                packIdentifier: file.pack.id,
                name: file.pack.name,
                installedVersion: file.pack.version,
                publisherId: file.pack.publisherId,
                publisherName: file.pack.publisherName,
                trustState: result.trustState,
                installState: .installed,
                manifestData: encodedFile,
                lastValidationAt: Date()
            ))
        }

        for module in file.modules {
            try registry.registerManifest(module.manifest)
            try upsertInstance(for: module, enabled: file.pack.isEnabledByDefault, approvedCapabilities: approvedCapabilities)
        }

        try context.save()
    }

    func disablePack(_ record: ModulePackRecord) throws {
        guard let file = record.packFile else { throw ModulePackError.invalidFile("Stored pack data is unreadable.") }
        let instances = try context.fetch(FetchDescriptor<ModuleInstance>())
        let ids = Set(file.modules.map(\.manifest.id))
        for instance in instances where ids.contains(instance.moduleIdentifier) && instance.archivedAt == nil {
            instance.isEnabled = false
            instance.updatedAt = Date()
        }
        record.installState = .disabled
        record.disabledAt = Date()
        record.updatedAt = Date()
        try context.save()
    }

    func enablePack(_ record: ModulePackRecord) throws {
        guard let file = record.packFile else { throw ModulePackError.invalidFile("Stored pack data is unreadable.") }
        let instances = try context.fetch(FetchDescriptor<ModuleInstance>())
        let ids = Set(file.modules.map(\.manifest.id))
        for instance in instances where ids.contains(instance.moduleIdentifier) && instance.archivedAt == nil {
            instance.isEnabled = true
            instance.updatedAt = Date()
        }
        record.installState = .installed
        record.disabledAt = nil
        record.updatedAt = Date()
        try context.save()
    }

    func uninstallPack(_ record: ModulePackRecord) throws {
        guard let file = record.packFile else { throw ModulePackError.invalidFile("Stored pack data is unreadable.") }
        let instances = try context.fetch(FetchDescriptor<ModuleInstance>())
        let ids = Set(file.modules.map(\.manifest.id))
        for instance in instances where ids.contains(instance.moduleIdentifier) && instance.archivedAt == nil {
            instance.archivedAt = Date()
            instance.isEnabled = false
            instance.updatedAt = Date()
        }
        record.archivedAt = Date()
        record.installState = .disabled
        record.updatedAt = Date()
        try context.save()
    }

    func rollbackPack(_ record: ModulePackRecord, registry: ModuleRegistry) throws {
        guard let previousData = record.previousVersionData,
              let previousFile = try? JSONDecoder().decode(ModulePackFile.self, from: previousData) else {
            throw ModulePackError.rollbackUnavailable
        }

        for module in previousFile.modules {
            try registry.registerManifest(module.manifest)
            try upsertInstance(for: module, enabled: true, approvedCapabilities: Set(module.manifest.capabilities))
        }

        record.manifestData = previousData
        record.installedVersion = previousFile.pack.version
        record.installState = .installed
        record.disabledAt = nil
        record.updatedAt = Date()
        try context.save()
    }

    private func upsertInstance(for module: ModulePackModuleDefinition, enabled: Bool, approvedCapabilities: Set<ModuleCapability>) throws {
        let instances = try context.fetch(FetchDescriptor<ModuleInstance>())
        let placement = module.manifest.placements.first ?? .dashboardCompact
        let configurationData = try JSONEncoder().encode(module.configuration)

        if let existing = instances.first(where: { $0.moduleIdentifier == module.manifest.id && $0.placement == placement && $0.archivedAt == nil }) {
            existing.configurationData = configurationData
            existing.isEnabled = enabled && Set(module.manifest.capabilities).isSubset(of: approvedCapabilities)
            existing.updatedAt = Date()
        } else {
            let order = instances.filter { $0.placement == placement && $0.archivedAt == nil }.count
            context.insert(ModuleInstance(moduleIdentifier: module.manifest.id, placement: placement, configurationData: configurationData, order: order, isEnabled: enabled && Set(module.manifest.capabilities).isSubset(of: approvedCapabilities)))
        }

        try upsertPermissionGrants(for: module.manifest, approvedCapabilities: approvedCapabilities)
    }

    private func upsertPermissionGrants(for manifest: ModuleManifest, approvedCapabilities: Set<ModuleCapability>) throws {
        let grants = try context.fetch(FetchDescriptor<ModulePermissionGrant>())
        for capability in manifest.capabilities where !capability.isForbidden {
            let isGranted = approvedCapabilities.contains(capability)
            if let existing = grants.first(where: { $0.moduleIdentifier == manifest.id && $0.capability == capability }) {
                existing.isGranted = isGranted
                existing.grantedAt = isGranted ? Date() : existing.grantedAt
                existing.revokedAt = isGranted ? nil : Date()
                existing.updatedAt = Date()
            } else {
                context.insert(ModulePermissionGrant(moduleIdentifier: manifest.id, capability: capability, isGranted: isGranted, grantedAt: isGranted ? Date() : nil, revokedAt: isGranted ? nil : Date()))
            }
        }
    }
}

enum ModulePackExporter {
    static func unsignedPack(pack: ModulePackManifest, modules: [ModulePackModuleDefinition], assets: [ModulePackAsset] = []) throws -> Data {
        var file = ModulePackFile(pack: pack, modules: modules, assets: assets)
        file.integrity = try ModulePackHashing.expectedIntegrity(for: file)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(file)
    }
}

enum ModulePackConfigurationMigrator {
    static func canMigrate(from oldVersion: String, to newVersion: String) -> Bool {
        guard let old = SemanticVersion(oldVersion), let new = SemanticVersion(newVersion) else {
            return true
        }
        return old.isCompatible(with: new)
    }

    static func migrateConfiguration(_ data: Data?, from oldVersion: String, to newVersion: String) throws -> Data? {
        guard canMigrate(from: oldVersion, to: newVersion) else {
            throw ModulePackError.migrationFailed("Major version changed from \(oldVersion) to \(newVersion).")
        }
        return data
    }
}
