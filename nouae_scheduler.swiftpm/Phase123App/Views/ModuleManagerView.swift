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
    @Query private var draftRecords: [ModuleDraftRecord]

    @State private var tab: ModuleManagerTab = .installed
    @State private var importText = ""
    @State private var importPreview: ModuleManifest?
    @State private var message: String?
    @State private var builderDraft: ModuleBuilderDraft?

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
        .sheet(item: $builderDraft) { draft in
            ModuleBuilderView(draft: draft)
                .environmentObject(stores)
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
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "User Module Builder", subtitle: "Swift나 JSON 없이 작은 운영 도구를 구성합니다.")

            HStack(spacing: 8) {
                Button {
                    builderDraft = stores.moduleBuilderStore.newDraft(template: .blank)
                } label: {
                    Label("New Blank Module", systemImage: "plus.square")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    builderDraft = stores.moduleBuilderStore.newDraft(template: .metricCard)
                } label: {
                    Label("Metric Card", systemImage: "chart.bar")
                }
                .buttonStyle(.bordered)
            }

            AppDivider()

            Text("Templates")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(ModuleTemplateCatalog.templates) { template in
                Button {
                    builderDraft = stores.moduleBuilderStore.newDraft(template: template)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: templateIcon(template))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.title)
                                .font(.subheadline.weight(.semibold))
                            Text(templateDescription(template))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                AppDivider()
            }

            Text("Drafts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            if activeDraftRecords.isEmpty {
                Text("새 Module을 만들어 nou ae를 자신의 흐름에 맞게 조정해보세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeDraftRecords) { record in
                    draftRow(record)
                }
            }
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

    private var activeDraftRecords: [ModuleDraftRecord] {
        draftRecords.filter { $0.archivedAt == nil }.sorted { $0.updatedAt > $1.updatedAt }
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
                if let manifest, manifest.origin == .user {
                    Button("Edit") {
                        builderDraft = draftFromInstalledModule(manifest: manifest, instance: instance)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)

                    Button("Duplicate") {
                        duplicateInstalledModule(manifest: manifest, instance: instance)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }

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

    private func draftRow(_ record: ModuleDraftRecord) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: record.draft?.iconSystemName ?? "square.grid.2x2")
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.name)
                    .font(.subheadline.weight(.semibold))
                Text(record.draft?.placement.title ?? "Draft")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(record.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("Open") {
                    if let draft = record.draft {
                        builderDraft = draft
                    }
                }
                Button("Duplicate") {
                    duplicate(record)
                }
                Button("Archive", role: .destructive) {
                    archiveDraft(record)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func duplicate(_ record: ModuleDraftRecord) {
        guard let draft = record.draft else {
            message = "Draft를 읽을 수 없습니다."
            return
        }
        do {
            let copy = stores.moduleBuilderStore.duplicateDraft(draft)
            try stores.moduleBuilderStore.saveDraft(copy)
            builderDraft = copy
            message = "Draft를 복제했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func archiveDraft(_ record: ModuleDraftRecord) {
        do {
            try stores.moduleBuilderStore.archiveDraft(record)
            message = "Draft를 archive했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func draftFromInstalledModule(manifest: ModuleManifest, instance: ModuleInstance) -> ModuleBuilderDraft {
        let configuration = instance.configurationData.flatMap { try? JSONDecoder().decode(DeclarativeModuleConfiguration.self, from: $0) }
        var draft = ModuleBuilderDraft(
            moduleIdentifier: manifest.id,
            name: manifest.name,
            descriptionText: manifest.descriptionText,
            category: ModuleCategory(rawValue: manifest.categoryRawValue) ?? .utility,
            iconSystemName: manifest.iconSystemName,
            placement: instance.placement,
            template: .blank,
            componentDefinitions: configuration?.components ?? [],
            dataBindings: [],
            actionDefinitions: [],
            requestedCapabilities: manifest.capabilities,
            version: manifest.version,
            createdAt: manifest.createdAt,
            updatedAt: Date(),
            lastValidatedAt: nil
        )
        if draft.componentDefinitions.isEmpty {
            draft.componentDefinitions = [ModuleComponentDefinition(type: .text, title: manifest.name, value: manifest.descriptionText, order: 0)]
        }
        return draft
    }

    private func duplicateInstalledModule(manifest: ModuleManifest, instance: ModuleInstance) {
        do {
            let draft = draftFromInstalledModule(manifest: manifest, instance: instance)
            let copy = stores.moduleBuilderStore.duplicateDraft(draft)
            try stores.moduleBuilderStore.saveDraft(copy)
            builderDraft = copy
            message = "설치된 Module을 Draft로 복제했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func templateIcon(_ template: ModuleBuilderTemplate) -> String {
        switch template {
        case .blank: return "square.grid.2x2"
        case .metricCard: return "chart.bar"
        case .listCard: return "list.bullet"
        case .progressCard: return "gauge.with.dots.needle.50percent"
        case .quickAction: return "bolt"
        case .logPreset: return "square.and.pencil"
        case .routineTemplate: return "repeat.circle"
        case .projectSummary: return "folder.badge.gearshape"
        }
    }

    private func templateDescription(_ template: ModuleBuilderTemplate) -> String {
        switch template {
        case .blank: return "빈 구조에서 직접 구성합니다."
        case .metricCard: return "Dashboard나 Tracker에 숫자 지표를 표시합니다."
        case .listCard: return "현재 context의 짧은 목록을 표시합니다."
        case .progressCard: return "완료율과 진행 상태를 보여줍니다."
        case .quickAction: return "자주 쓰는 행동을 가까이에 둡니다."
        case .logPreset: return "짧은 회고 입력을 시작합니다."
        case .routineTemplate: return "Routine 생성 흐름을 가까이에 둡니다."
        case .projectSummary: return "Project Dashboard에 요약 카드를 둡니다."
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
