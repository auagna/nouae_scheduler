import Foundation
import SwiftData

enum ModulePackCategory: String, CaseIterable, Identifiable, Codable {
    case planning
    case project
    case reflection
    case routine
    case creative
    case study
    case health
    case professional
    case utility

    var id: String { rawValue }
}

enum ModulePackTrustState: String, CaseIterable, Identifiable, Codable {
    case builtIn
    case verified
    case unverified
    case invalid
    case revoked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .builtIn: return "nou ae built-in pack"
        case .verified: return "Verified publisher"
        case .unverified: return "Unsigned local pack"
        case .invalid: return "Invalid pack"
        case .revoked: return "Revoked publisher"
        }
    }
}

enum ModulePackInstallState: String, CaseIterable, Identifiable, Codable {
    case staged
    case installed
    case updateAvailable
    case needsPermissionReview
    case needsReconfiguration
    case disabled
    case failed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .staged: return "Staged"
        case .installed: return "Installed"
        case .updateAvailable: return "Update Available"
        case .needsPermissionReview: return "Permission Review"
        case .needsReconfiguration: return "Needs Reconfiguration"
        case .disabled: return "Disabled"
        case .failed: return "Failed"
        }
    }
}

struct SemanticVersion: Codable, Comparable, CustomStringConvertible, Equatable {
    var major: Int
    var minor: Int
    var patch: Int
    var prerelease: String?

    init(major: Int, minor: Int, patch: Int, prerelease: String? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
    }

    init?(_ value: String) {
        let parts = value.split(separator: "-", maxSplits: 1).map(String.init)
        let numbers = parts.first?.split(separator: ".").compactMap { Int($0) } ?? []
        guard numbers.count == 3 else { return nil }
        major = numbers[0]
        minor = numbers[1]
        patch = numbers[2]
        prerelease = parts.count > 1 ? parts[1] : nil
    }

    var description: String {
        if let prerelease, !prerelease.isEmpty {
            return "\(major).\(minor).\(patch)-\(prerelease)"
        }
        return "\(major).\(minor).\(patch)"
    }

    var isPrerelease: Bool {
        prerelease?.isEmpty == false
    }

    func isNewer(than other: SemanticVersion) -> Bool {
        self > other
    }

    func isCompatible(with other: SemanticVersion) -> Bool {
        major == other.major
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil): return false
        case (nil, _?): return false
        case (_?, nil): return true
        case let (left?, right?): return left < right
        }
    }
}

struct ModulePackManifest: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var descriptionText: String
    var version: String
    var schemaVersion: Int
    var minimumAppVersion: String
    var publisherId: String
    var publisherName: String
    var author: String
    var categoryRawValue: String
    var iconSystemName: String
    var releaseNotes: String
    var moduleIdentifiers: [String]
    var requiredCapabilitiesRawValue: String
    var optionalCapabilitiesRawValue: String
    var dependencyIdentifiers: [String]
    var isEnabledByDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        name: String,
        descriptionText: String,
        version: String,
        schemaVersion: Int = 1,
        minimumAppVersion: String = "1.0.0",
        publisherId: String,
        publisherName: String,
        author: String,
        category: ModulePackCategory,
        iconSystemName: String = "shippingbox",
        releaseNotes: String = "",
        moduleIdentifiers: [String],
        requiredCapabilities: [ModuleCapability] = [],
        optionalCapabilities: [ModuleCapability] = [],
        dependencyIdentifiers: [String] = [],
        isEnabledByDefault: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.version = version
        self.schemaVersion = schemaVersion
        self.minimumAppVersion = minimumAppVersion
        self.publisherId = publisherId
        self.publisherName = publisherName
        self.author = author
        categoryRawValue = category.rawValue
        self.iconSystemName = iconSystemName
        self.releaseNotes = releaseNotes
        self.moduleIdentifiers = moduleIdentifiers
        requiredCapabilitiesRawValue = requiredCapabilities.map(\.rawValue).joined(separator: ",")
        optionalCapabilitiesRawValue = optionalCapabilities.map(\.rawValue).joined(separator: ",")
        self.dependencyIdentifiers = dependencyIdentifiers
        self.isEnabledByDefault = isEnabledByDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension ModulePackManifest {
    var category: ModulePackCategory { ModulePackCategory(rawValue: categoryRawValue) ?? .utility }
    var requiredCapabilities: [ModuleCapability] { requiredCapabilitiesRawValue.packRawValues().compactMap(ModuleCapability.init(rawValue:)) }
    var optionalCapabilities: [ModuleCapability] { optionalCapabilitiesRawValue.packRawValues().compactMap(ModuleCapability.init(rawValue:)) }
    var semanticVersion: SemanticVersion? { SemanticVersion(version) }
}

struct ModulePackAsset: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var mimeType: String
    var base64Data: String
    var byteCount: Int
    var checksum: String?

    init(id: UUID = UUID(), name: String, mimeType: String, base64Data: String, byteCount: Int, checksum: String? = nil) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.base64Data = base64Data
        self.byteCount = byteCount
        self.checksum = checksum
    }
}

struct ModulePackIntegrity: Codable, Equatable {
    var algorithm: String
    var manifestHash: String
    var modulesHash: String
    var assetsHash: String?
    var fullPayloadHash: String

    init(algorithm: String = "SHA256", manifestHash: String, modulesHash: String, assetsHash: String? = nil, fullPayloadHash: String) {
        self.algorithm = algorithm
        self.manifestHash = manifestHash
        self.modulesHash = modulesHash
        self.assetsHash = assetsHash
        self.fullPayloadHash = fullPayloadHash
    }
}

struct ModulePackSignature: Codable, Equatable {
    var algorithm: String
    var publisherId: String
    var signatureBase64: String
    var signedPayloadHash: String
    var signedAt: Date
}

struct TrustedPublisher: Identifiable, Codable, Equatable {
    var id: String { publisherId }
    var publisherId: String
    var publisherName: String
    var publicKeyData: Data
    var algorithmRawValue: String
    var addedAt: Date
    var revokedAt: Date?
}

struct ModulePackModuleDefinition: Identifiable, Codable, Equatable {
    var id: String { manifest.id }
    var manifest: ModuleManifest
    var components: [ModuleComponentDefinition]

    init(manifest: ModuleManifest, components: [ModuleComponentDefinition]) {
        self.manifest = manifest
        self.components = components
    }

    var configuration: DeclarativeModuleConfiguration {
        DeclarativeModuleConfiguration(components: components.sorted { ($0.order ?? 0) < ($1.order ?? 0) })
    }
}

struct ModulePackFile: Codable, Equatable {
    var pack: ModulePackManifest
    var modules: [ModulePackModuleDefinition]
    var assets: [ModulePackAsset]
    var integrity: ModulePackIntegrity?
    var signature: ModulePackSignature?

    init(pack: ModulePackManifest, modules: [ModulePackModuleDefinition], assets: [ModulePackAsset] = [], integrity: ModulePackIntegrity? = nil, signature: ModulePackSignature? = nil) {
        self.pack = pack
        self.modules = modules
        self.assets = assets
        self.integrity = integrity
        self.signature = signature
    }
}

struct ModulePackValidationResult: Identifiable {
    var id: String { packFile?.pack.id ?? UUID().uuidString }
    var packFile: ModulePackFile?
    var errors: [String]
    var warnings: [String]
    var trustState: ModulePackTrustState
    var requestedCapabilities: [ModuleCapabilityRequest]
    var moduleDiff: ModulePackDiff
    var isInstallable: Bool { errors.isEmpty && trustState != .invalid && trustState != .revoked }
}

struct ModulePackDiff: Codable, Equatable {
    var added: [String]
    var removed: [String]
    var updated: [String]
    var unchanged: [String]

    static var empty: ModulePackDiff {
        ModulePackDiff(added: [], removed: [], updated: [], unchanged: [])
    }
}

enum ModulePackError: LocalizedError {
    case invalidFile(String)
    case fileTooLarge
    case decodeFailed
    case invalidIntegrity
    case invalidSignature
    case unknownPublisher
    case revokedPublisher
    case unsupportedSchema
    case incompatibleAppVersion
    case duplicateModuleIdentifier
    case invalidModule(String)
    case dependencyMissing(String)
    case circularDependency
    case permissionRequired
    case installFailed(String)
    case updateFailed(String)
    case migrationFailed(String)
    case rollbackUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidFile(let message): return message
        case .fileTooLarge: return "The pack is larger than 5MB."
        case .decodeFailed: return "The pack JSON could not be decoded."
        case .invalidIntegrity: return "The pack appears damaged or modified."
        case .invalidSignature: return "The pack signature is invalid."
        case .unknownPublisher: return "The publisher is not trusted on this device."
        case .revokedPublisher: return "The publisher has been revoked."
        case .unsupportedSchema: return "This pack schema is not supported."
        case .incompatibleAppVersion: return "This Module Pack requires a newer nou ae version."
        case .duplicateModuleIdentifier: return "The pack contains duplicate module identifiers."
        case .invalidModule(let message): return "Invalid module: \(message)"
        case .dependencyMissing(let identifier): return "Missing dependency: \(identifier)"
        case .circularDependency: return "The pack contains a circular dependency."
        case .permissionRequired: return "Required capability approval is missing."
        case .installFailed(let message): return "Pack install failed: \(message)"
        case .updateFailed(let message): return "Pack update failed: \(message)"
        case .migrationFailed(let message): return "Configuration migration failed: \(message)"
        case .rollbackUnavailable: return "Rollback is not available."
        }
    }
}

@Model
final class ModulePackRecord {
    @Attribute(.unique) var id: UUID
    var packIdentifier: String
    var name: String
    var installedVersion: String
    var publisherId: String
    var publisherName: String
    var trustStateRawValue: String
    var installStateRawValue: String
    var manifestData: Data
    var installedAt: Date
    var updatedAt: Date
    var disabledAt: Date?
    var archivedAt: Date?
    var previousVersionData: Data?
    var previousManifestData: Data?
    var lastValidationAt: Date?
    var lastErrorMessage: String?

    init(
        id: UUID = UUID(),
        packIdentifier: String,
        name: String,
        installedVersion: String,
        publisherId: String,
        publisherName: String,
        trustState: ModulePackTrustState,
        installState: ModulePackInstallState,
        manifestData: Data,
        installedAt: Date = Date(),
        updatedAt: Date = Date(),
        disabledAt: Date? = nil,
        archivedAt: Date? = nil,
        previousVersionData: Data? = nil,
        previousManifestData: Data? = nil,
        lastValidationAt: Date? = nil,
        lastErrorMessage: String? = nil
    ) {
        self.id = id
        self.packIdentifier = packIdentifier
        self.name = name
        self.installedVersion = installedVersion
        self.publisherId = publisherId
        self.publisherName = publisherName
        trustStateRawValue = trustState.rawValue
        installStateRawValue = installState.rawValue
        self.manifestData = manifestData
        self.installedAt = installedAt
        self.updatedAt = updatedAt
        self.disabledAt = disabledAt
        self.archivedAt = archivedAt
        self.previousVersionData = previousVersionData
        self.previousManifestData = previousManifestData
        self.lastValidationAt = lastValidationAt
        self.lastErrorMessage = lastErrorMessage
    }
}

extension ModulePackRecord {
    var trustState: ModulePackTrustState {
        get { ModulePackTrustState(rawValue: trustStateRawValue) ?? .unverified }
        set { trustStateRawValue = newValue.rawValue }
    }

    var installState: ModulePackInstallState {
        get { ModulePackInstallState(rawValue: installStateRawValue) ?? .installed }
        set { installStateRawValue = newValue.rawValue }
    }

    var packFile: ModulePackFile? {
        try? JSONDecoder().decode(ModulePackFile.self, from: manifestData)
    }
}

private extension String {
    func packRawValues() -> [String] {
        split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}
