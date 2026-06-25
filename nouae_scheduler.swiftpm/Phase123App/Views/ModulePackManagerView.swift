import SwiftData
import SwiftUI
import UniformTypeIdentifiers

private enum ModulePackManagerTab: String, CaseIterable, Identifiable {
    case installed = "Installed"
    case importPack = "Import"
    case updates = "Updates"
    case publishers = "Publishers"

    var id: String { rawValue }
}

struct ModulePackManagerView: View {
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \ModulePackRecord.updatedAt, order: .reverse) private var packRecords: [ModulePackRecord]

    @State private var tab: ModulePackManagerTab = .installed
    @State private var importText = ""
    @State private var validationResult: ModulePackValidationResult?
    @State private var approvedCapabilityRawValues: Set<String> = []
    @State private var message: String?
    @State private var showingImporter = false

    var body: some View {
        AppPanel(title: "Module Packs", subtitle: "Install reviewed declarative module bundles without executable code.") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Packs", selection: $tab) {
                    ForEach(ModulePackManagerTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                switch tab {
                case .installed:
                    installedView
                case .importPack:
                    importView
                case .updates:
                    updatesView
                case .publishers:
                    publishersView
                }
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: ModulePackUTType.allowedContentTypes) { result in
            handleImportResult(result)
        }
    }

    private var installedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if activePackRecords.isEmpty {
                Text("No Module Packs installed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activePackRecords) { record in
                    installedPackRow(record)
                }
            }
        }
    }

    private var importView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    showingImporter = true
                } label: {
                    Label("Choose .nouaepack", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)

                Button("Validate Text") {
                    validateImportText()
                }
                .buttonStyle(.bordered)
            }

            Text(".nouaepack is JSON only. Swift, JavaScript, shell scripts, WebView apps, binaries, and direct EventKit access are rejected.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $importText)
                .font(.caption.monospaced())
                .frame(minHeight: 130)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.18), lineWidth: 1))

            if let validationResult {
                importPreview(validationResult)
            }
        }
    }

    private var updatesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Remote catalogs are not part of the MVP. Import a higher local .nouaepack version to enter the update flow.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(packRecords.filter { $0.installState == .updateAvailable && $0.archivedAt == nil }) { record in
                installedPackRow(record)
            }
        }
    }

    private var publishersView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(TrustedPublisherRegistry.builtInPublishers) { publisher in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal")
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(publisher.publisherName)
                            .font(.subheadline.weight(.semibold))
                        Text(publisher.publisherId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Algorithm: \(publisher.algorithmRawValue)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(publisher.revokedAt == nil ? "Trusted" : "Revoked", tone: publisher.revokedAt == nil ? .green : .orange)
                }
                AppDivider()
            }
        }
    }

    private var activePackRecords: [ModulePackRecord] {
        packRecords.filter { $0.archivedAt == nil }
    }

    private func installedPackRow(_ record: ModulePackRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: record.packFile?.pack.iconSystemName ?? "shippingbox")
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.name)
                        .font(.subheadline.weight(.semibold))
                    Text("\(record.publisherName) - \(record.installedVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let error = record.lastErrorMessage, !error.isEmpty {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(record.trustState.title, tone: tone(for: record.trustState))
                    StatusBadge(record.installState.title, tone: tone(for: record.installState))
                }
            }

            if let packFile = record.packFile {
                Text("\(packFile.modules.count) modules - \(packFile.assets.count) assets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(record.installState == .disabled ? "Enable" : "Disable") {
                    toggle(record)
                }
                .buttonStyle(.bordered)
                .font(.caption)

                Button("Rollback") {
                    rollback(record)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .disabled(record.previousVersionData == nil)

                Button("Uninstall", role: .destructive) {
                    uninstall(record)
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func importPreview(_ result: ModulePackValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AppDivider()

            if let packFile = result.packFile {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(packFile.pack.name)
                            .font(.headline)
                        Text("\(packFile.pack.publisherName) - \(packFile.pack.version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(result.trustState.title, tone: tone(for: result.trustState))
                }

                if !packFile.pack.releaseNotes.isEmpty {
                    Text(packFile.pack.releaseNotes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Modules")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(packFile.modules) { module in
                    HStack {
                        Image(systemName: module.manifest.iconSystemName)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(module.manifest.name)
                                .font(.caption.weight(.semibold))
                            Text(module.manifest.placements.map(\.title).joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(module.manifest.version)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                moduleDiffView(result.moduleDiff)
            }

            if !result.errors.isEmpty {
                ForEach(result.errors, id: \.self) { error in
                    Label(error, systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if !result.warnings.isEmpty {
                ForEach(result.warnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            if !result.requestedCapabilities.isEmpty {
                Text("Permissions")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(result.requestedCapabilities) { request in
                    Toggle(isOn: capabilityBinding(request.capability)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.capability.title)
                                .font(.caption.weight(.semibold))
                            Text(request.reason)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Button("Install Pack") {
                installValidationResult(result)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!result.isInstallable)
        }
    }

    private func moduleDiffView(_ diff: ModulePackDiff) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Update Diff")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack {
                StatusBadge("Added \(diff.added.count)", tone: diff.added.isEmpty ? .neutral : .blue)
                StatusBadge("Updated \(diff.updated.count)", tone: diff.updated.isEmpty ? .neutral : .orange)
                StatusBadge("Removed \(diff.removed.count)", tone: diff.removed.isEmpty ? .neutral : .red)
            }
        }
    }

    private func capabilityBinding(_ capability: ModuleCapability) -> Binding<Bool> {
        Binding(
            get: { approvedCapabilityRawValues.contains(capability.rawValue) },
            set: { isOn in
                if isOn {
                    approvedCapabilityRawValues.insert(capability.rawValue)
                } else {
                    approvedCapabilityRawValues.remove(capability.rawValue)
                }
            }
        )
    }

    private func validateImportText() {
        guard let data = importText.data(using: .utf8) else {
            message = "Import text is not UTF-8."
            return
        }
        validate(data)
    }

    private func validate(_ data: Data) {
        let result = stores.modulePackStore.validate(data: data, registry: stores.moduleRegistry)
        validationResult = result
        approvedCapabilityRawValues = Set(result.requestedCapabilities.map { $0.capability.rawValue })
        message = result.isInstallable ? "Pack validation complete." : "Pack validation failed."
    }

    private func installValidationResult(_ result: ModulePackValidationResult) {
        do {
            let capabilities = Set(result.requestedCapabilities.map(\.capability).filter { approvedCapabilityRawValues.contains($0.rawValue) })
            try stores.modulePackStore.install(result, registry: stores.moduleRegistry, approvedCapabilities: capabilities)
            validationResult = nil
            importText = ""
            message = "Module Pack installed."
        } catch {
            message = error.localizedDescription
        }
    }

    private func toggle(_ record: ModulePackRecord) {
        do {
            if record.installState == .disabled {
                try stores.modulePackStore.enable(record)
                message = "Pack enabled."
            } else {
                try stores.modulePackStore.disable(record)
                message = "Pack disabled."
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func rollback(_ record: ModulePackRecord) {
        do {
            try stores.modulePackStore.rollback(record, registry: stores.moduleRegistry)
            message = "Pack rolled back."
        } catch {
            message = error.localizedDescription
        }
    }

    private func uninstall(_ record: ModulePackRecord) {
        do {
            try stores.modulePackStore.uninstall(record)
            message = "Pack uninstalled. Core data remains."
        } catch {
            message = error.localizedDescription
        }
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            importText = String(data: data, encoding: .utf8) ?? ""
            validate(data)
        } catch {
            message = error.localizedDescription
        }
    }

    private func tone(for trustState: ModulePackTrustState) -> StatusBadge.Tone {
        switch trustState {
        case .builtIn, .verified: return .green
        case .unverified: return .orange
        case .invalid, .revoked: return .red
        }
    }

    private func tone(for installState: ModulePackInstallState) -> StatusBadge.Tone {
        switch installState {
        case .installed: return .green
        case .staged, .updateAvailable, .needsPermissionReview, .needsReconfiguration: return .orange
        case .disabled: return .neutral
        case .failed: return .red
        }
    }
}

enum ModulePackUTType {
    static var allowedContentTypes: [UTType] {
        var types: [UTType] = []
        if let packType = UTType(filenameExtension: "nouaepack") {
            types.append(packType)
        }
        types.append(.json)
        return types
    }
}
