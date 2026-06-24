import SwiftData
import SwiftUI

enum ModuleHostLayoutStyle: String {
    case compact
    case regular
    case prominent
}

struct ModuleHostView: View {
    let placement: ModulePlacement
    var projectId: UUID?
    var areaId: UUID?
    var layoutStyle: ModuleHostLayoutStyle = .regular

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var stores: AppStores
    @Query(sort: \ModuleInstance.order) private var instances: [ModuleInstance]
    @Query private var grants: [ModulePermissionGrant]
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \RawTask.createdAt, order: .reverse) private var tasks: [RawTask]
    @Query(sort: \WorkBlock.startAt) private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]

    var body: some View {
        Group {
            if renderItems.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: layoutStyle == .compact ? 8 : 12) {
                    ForEach(renderItems) { item in
                        render(item)
                    }
                }
            }
        }
        .task {
            try? stores.moduleRegistry.installBuiltInDefaults(context: modelContext)
        }
    }

    private var renderItems: [ModuleRenderDescriptor] {
        stores.moduleRegistry.enabledModules(for: placement, instances: instances)
    }

    private var permissionStore: ModulePermissionStore {
        ModulePermissionStore(grants: grants)
    }

    private func context(for item: ModuleRenderDescriptor) -> ModuleContext {
        ModuleContext(
            moduleIdentifier: item.manifest.id,
            currentDate: Date(),
            selectedAreaId: areaId,
            selectedProjectId: projectId,
            currentPlacement: placement,
            projects: projects,
            tasks: tasks,
            workBlocks: blocks,
            logs: logs,
            routines: stores.routineStore.routines,
            permissionStore: permissionStore,
            actionRouter: ModuleActionRouter(stores: stores)
        )
    }

    @ViewBuilder
    private func render(_ item: ModuleRenderDescriptor) -> some View {
        let moduleContext = context(for: item)
        if !permissionStore.hasRequiredCapabilities(for: item.manifest) {
            ModuleErrorCard(moduleName: item.manifest.name, error: ModuleError.permissionDenied(item.manifest.capabilities.first ?? .readProjects)) {
                item.instance.isEnabled = false
                item.instance.updatedAt = Date()
                try? modelContext.save()
            }
        } else if item.manifest.entryType == .native {
            if let module = stores.moduleRegistry.nativeModule(for: item.manifest.id) {
                module.makeView(context: moduleContext)
            } else {
                ModuleErrorCard(moduleName: item.manifest.name, error: .renderingFailed("Native Module이 registry에 없습니다.")) {
                    item.instance.isEnabled = false
                    try? modelContext.save()
                }
            }
        } else {
            DeclarativeModuleRenderer(manifest: item.manifest, instance: item.instance, context: moduleContext)
        }
    }
}

struct DeclarativeModuleRenderer: View {
    let manifest: ModuleManifest
    let instance: ModuleInstance
    let context: ModuleContext

    private var configuration: DeclarativeModuleConfiguration? {
        guard let data = instance.configurationData else { return nil }
        return try? JSONDecoder().decode(DeclarativeModuleConfiguration.self, from: data)
    }

    var body: some View {
        let components = Array((configuration?.components ?? []).prefix(20))
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(manifest.name, systemImage: manifest.iconSystemName)
                    .font(.subheadline.weight(.semibold))
                if components.isEmpty {
                    Text(manifest.descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(components) { component in
                        render(component, depth: 0)
                    }
                }
            }
        }
    }

    private func render(_ component: ModuleComponentDefinition, depth: Int) -> AnyView {
        guard depth <= 3 else { return AnyView(EmptyView()) }
        guard let type = component.type else {
            return AnyView(Text("Unsupported component").font(.caption).foregroundStyle(.secondary))
        }

        switch type {
        case .sectionHeader:
            return AnyView(Text(component.title).font(.headline))
        case .text:
            return AnyView(Text(component.value.isEmpty ? component.title : component.value).font(.subheadline))
        case .metric:
            return AnyView(HStack { Text(component.title).foregroundStyle(.secondary); Spacer(); Text(component.value).font(.headline) })
        case .progress:
            return AnyView(VStack(alignment: .leading, spacing: 6) { Text(component.title).font(.caption); ProgressView(value: min(max(Double(component.value) ?? 0, 0), 1)) })
        case .divider:
            return AnyView(AppDivider())
        case .button:
            return AnyView(Button(component.title.isEmpty ? "Run" : component.title) { run(component.action, title: component.title, value: component.value) }.buttonStyle(.bordered))
        case .tagList:
            let tags = component.value.split(separator: ",").map(String.init)
            return AnyView(HStack(spacing: 6) { ForEach(tags.prefix(6), id: \.self) { Text($0).font(.caption2).padding(.horizontal, 8).padding(.vertical, 4).background(Color.secondary.opacity(0.12), in: Capsule()) } })
        case .list, .checklist:
            return AnyView(VStack(alignment: .leading, spacing: 6) { ForEach(component.children.prefix(8)) { child in render(child, depth: depth + 1) } })
        case .activityDots, .compactChart:
            return AnyView(HStack(spacing: 4) { ForEach(0..<7, id: \.self) { index in Circle().fill(index % 2 == 0 ? Color.accentColor.opacity(0.7) : Color.secondary.opacity(0.18)).frame(width: 8, height: 8) } })
        case .link:
            return AnyView(Text(component.value.isEmpty ? component.title : component.value).font(.caption).foregroundStyle(.blue))
        case .noteInput, .dateInput, .toggle:
            return AnyView(Text(component.title).font(.caption).foregroundStyle(.secondary))
        }
    }

    private func run(_ action: ModuleDeclarativeActionType?, title: String, value: String) {
        guard let action else { return }
        let mapped: ModuleActionType
        switch action {
        case .createTask: mapped = .createTask
        case .createLog: mapped = .createLog
        case .createNote: mapped = .createNote
        case .createRoutine: mapped = .createRoutine
        case .createAdjustment: mapped = .createAdjustment
        case .openDestination: mapped = .openPlan
        case .toggleValue, .updateModuleField: mapped = .updateModuleField
        }
        Task { @MainActor in
            try? await context.actionRouter?.handle(ModuleAction(type: mapped, title: title, payload: ["title": title, "content": value]), context: context)
        }
    }
}
