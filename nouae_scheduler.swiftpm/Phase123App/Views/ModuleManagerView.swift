import SwiftData
import SwiftUI

private enum ModuleManagerTab: String, CaseIterable, Identifiable {
    case installed = "Installed"
    case available = "Available"
    case create = "Create"
    case importPack = "Import"

    var id: String { rawValue }
}

struct ModuleManagerView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \ModuleInstance.order) private var instances: [ModuleInstance]
    @Query private var grants: [ModulePermissionGrant]

    @State private var tab: ModuleManagerTab = .installed
    @State private var importText = ""
    @State private var importPreview: ModuleManifest?
    @State private var message: String?

    var body: some View {
        AppPanel(title: "Modules", subtitle: "Core를 대체하지 않는 보조 기능 슬롯입니다.") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Modules", selection: $tab) {
                    ForEach(ModuleManagerTab.allCases) { tab in
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
                case .available:
                    availableView
                case .create:
                    createView
                case .importPack:
                    importView
                }
            }
        }
        .task {
            try? stores.moduleRegistry.installBuiltInDefaults(context: context)
        }
    }

    private var installedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if activeInstances.isEmpty {
                Text("설치된 Module이 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeInstances) { instance in
                    moduleInstanceRow(instance)
                }
            }
        }
    }

    private var availableView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(stores.moduleRegistry.allManifests) { manifest in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: manifest.iconSystemName)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(manifest.name)
                            .font(.subheadline.weight(.semibold))
                        Text(manifest.descriptionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(manifest.placements.map(\.title).joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if installedModuleIds.contains(manifest.id) {
                        StatusBadge("Installed", tone: .neutral)
                    } else {
                        Button("Install") {
                            install(manifest)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                AppDivider()
            }
        }
    }

    private var createView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("User Module Builder")
                .font(.subheadline.weight(.semibold))
            Text("코드 없는 Field / View / Action 조합 Builder는 다음 단계에서 연결합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var importView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(".nouaemodule 또는 JSON manifest 내용을 붙여넣어 검증합니다. 실행 코드는 허용하지 않습니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $importText)
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.18), lineWidth: 1))
            HStack {
                Button("Validate") {
                    validateImport()
                }
                .buttonStyle(.bordered)

                if let importPreview {
                    Button("Install") {
                        install(importPreview)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            if let importPreview {
                Text("Preview: \(importPreview.name) · \(importPreview.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var activeInstances: [ModuleInstance] {
        instances.filter { $0.archivedAt == nil }.sorted { $0.order < $1.order }
    }

    private var installedModuleIds: Set<String> {
        Set(activeInstances.map(\.moduleIdentifier))
    }

    private func moduleInstanceRow(_ instance: ModuleInstance) -> some View {
        let manifest = stores.moduleRegistry.module(for: instance.moduleIdentifier)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: manifest?.iconSystemName ?? "shippingbox")
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(manifest?.name ?? instance.moduleIdentifier)
                        .font(.subheadline.weight(.semibold))
                    Text(instance.placement.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("Enabled", isOn: Binding(get: { instance.isEnabled }, set: { value in update(instance, enabled: value) }))
                    .labelsHidden()
            }

            if let manifest {
                DisclosureGroup("Permissions") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(manifest.capabilities.filter { !$0.isForbidden }) { capability in
                            Toggle(capability.title, isOn: permissionBinding(moduleIdentifier: manifest.id, capability: capability))
                                .font(.caption)
                        }
                    }
                    .padding(.top, 6)
                }
                .font(.caption.weight(.semibold))
            }

            HStack {
                Button("Archive", role: .destructive) {
                    archive(instance)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                Spacer()
                Stepper("Order \(instance.order)", value: Binding(get: { instance.order }, set: { value in update(instance, order: value) }), in: 0...99)
                    .font(.caption)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func install(_ manifest: ModuleManifest) {
        do {
            let placement = manifest.placements.first ?? .dashboardCompact
            _ = try stores.moduleRegistry.installModule(manifest, placement: placement, context: context)
            message = "\(manifest.name)을 설치했습니다."
            importPreview = nil
            importText = ""
        } catch {
            message = error.localizedDescription
        }
    }

    private func update(_ instance: ModuleInstance, enabled: Bool) {
        instance.isEnabled = enabled
        instance.updatedAt = Date()
        try? context.save()
    }

    private func update(_ instance: ModuleInstance, order: Int) {
        instance.order = order
        instance.updatedAt = Date()
        try? context.save()
    }

    private func archive(_ instance: ModuleInstance) {
        stores.moduleRegistry.archiveModuleInstance(instance)
        try? context.save()
    }

    private func permissionBinding(moduleIdentifier: String, capability: ModuleCapability) -> Binding<Bool> {
        Binding(
            get: { grant(moduleIdentifier: moduleIdentifier, capability: capability)?.isGranted ?? false },
            set: { value in setGrant(moduleIdentifier: moduleIdentifier, capability: capability, isGranted: value) }
        )
    }

    private func grant(moduleIdentifier: String, capability: ModuleCapability) -> ModulePermissionGrant? {
        grants.first { $0.moduleIdentifier == moduleIdentifier && $0.capability == capability }
    }

    private func setGrant(moduleIdentifier: String, capability: ModuleCapability, isGranted: Bool) {
        if let existing = grant(moduleIdentifier: moduleIdentifier, capability: capability) {
            existing.isGranted = isGranted
            existing.grantedAt = isGranted ? Date() : existing.grantedAt
            existing.revokedAt = isGranted ? nil : Date()
            existing.updatedAt = Date()
        } else {
            context.insert(ModulePermissionGrant(moduleIdentifier: moduleIdentifier, capability: capability, isGranted: isGranted, grantedAt: isGranted ? Date() : nil, revokedAt: isGranted ? nil : Date()))
        }
        try? context.save()
    }

    private func validateImport() {
        do {
            guard let data = importText.data(using: .utf8) else {
                throw ModuleError.invalidManifest("텍스트를 UTF-8로 변환할 수 없습니다.")
            }
            let manifest = try ModuleImportValidator.validate(data: data)
            try stores.moduleRegistry.validateManifest(manifest)
            importPreview = manifest
            message = "검증 완료: \(manifest.name)"
        } catch {
            importPreview = nil
            message = error.localizedDescription
        }
    }
}
