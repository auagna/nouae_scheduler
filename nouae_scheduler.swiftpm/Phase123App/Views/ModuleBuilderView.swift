import SwiftData
import SwiftUI

struct ModuleBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stores: AppStores

    @State private var draft: ModuleBuilderDraft
    @State private var selectedStep: ModuleBuilderStep = .purpose
    @State private var selectedComponentId: UUID?
    @State private var approvedCapabilityRawValues: Set<String> = []
    @State private var message: String?
    @State private var exportText = ""
    @State private var history: [ModuleBuilderDraft] = []
    @State private var redoStack: [ModuleBuilderDraft] = []

    init(draft: ModuleBuilderDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                AppScreenContainer(spacing: 14) {
                    builderHeader

                    if geometry.size.width >= 920 {
                        HStack(alignment: .top, spacing: 14) {
                            stepSidebar
                                .frame(width: max(210, geometry.size.width * 0.23), alignment: .topLeading)
                            livePreview
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            inspector
                                .frame(width: max(280, geometry.size.width * 0.30), alignment: .topLeading)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            stepSidebar
                            livePreview
                            inspector
                        }
                    }
                }
            }
            .navigationTitle("Module Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            refreshValidation()
        }
    }

    private var builderHeader: some View {
        AppPanel(title: "Module Builder", subtitle: "코드 없이 작은 운영 도구를 구성합니다.") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: draft.iconSystemName.isEmpty ? "square.grid.2x2" : draft.iconSystemName)
                        .font(.title2)
                        .frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(draft.name.isEmpty ? "Untitled Module" : draft.name)
                            .font(.headline)
                        Text(draft.descriptionText.isEmpty ? "Purpose를 입력하면 이 Module의 역할이 분명해집니다." : draft.descriptionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    StatusBadge(statusText, tone: statusTone)
                }

                HStack(spacing: 8) {
                    Button("Undo") { undo() }
                        .buttonStyle(.bordered)
                        .disabled(history.isEmpty)
                    Button("Redo") { redo() }
                        .buttonStyle(.bordered)
                        .disabled(redoStack.isEmpty)
                    Spacer()
                    Button("Save Draft") { saveDraft() }
                        .buttonStyle(.bordered)
                    Button("Install") { install() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!validation.isInstallable)
                }

                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var stepSidebar: some View {
        AppPanel(title: "구성", subtitle: "한 번에 하나의 개념만 조정합니다.") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(ModuleBuilderStep.allCases) { step in
                    Button {
                        selectedStep = step
                    } label: {
                        HStack {
                            Text(step.rawValue)
                                .font(.subheadline.weight(step == selectedStep ? .semibold : .regular))
                            Spacer()
                            if step == selectedStep {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(step == selectedStep ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var livePreview: some View {
        AppPanel(title: "Live Preview", subtitle: "\(draft.placement.title) · \(draft.template.title)") {
            VStack(alignment: .leading, spacing: 12) {
                ModuleDraftPreviewCard(draft: draft)
                validationSummary
            }
        }
    }

    @ViewBuilder
    private var inspector: some View {
        switch selectedStep {
        case .purpose:
            purposeInspector
        case .placement:
            placementInspector
        case .template:
            templateInspector
        case .data:
            dataInspector
        case .components:
            componentsInspector
        case .actions:
            actionsInspector
        case .permissions:
            permissionsInspector
        case .preview:
            previewInstallInspector
        }
    }

    private var purposeInspector: some View {
        AppPanel(title: "Purpose", subtitle: "Module이 해결할 일을 짧게 정합니다.") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Module 이름", text: binding(\.name))
                    .textFieldStyle(.roundedBorder)
                TextField("설명", text: binding(\.descriptionText), axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Picker("Category", selection: Binding(get: { draft.category }, set: { newValue in update { $0.category = newValue } })) {
                    ForEach(ModuleCategory.allCases) { category in
                        Text(category.rawValue.capitalized).tag(category)
                    }
                }
                TextField("SF Symbol", text: binding(\.iconSystemName))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var placementInspector: some View {
        AppPanel(title: "Placement", subtitle: "Core 화면의 안전한 slot에만 배치합니다.") {
            Picker("Placement", selection: Binding(get: { draft.placement }, set: { newValue in update { $0.placement = newValue } })) {
                ForEach(allowedPlacements) { placement in
                    Text(placement.title).tag(placement)
                }
            }
            .pickerStyle(.inline)
        }
    }

    private var templateInspector: some View {
        AppPanel(title: "Template", subtitle: "초기 구조만 만들고 이후 수정할 수 있습니다.") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(ModuleTemplateCatalog.templates) { template in
                    Button {
                        update { draft in
                            draft.name = draft.name.isEmpty ? ModuleTemplateCatalog.makeDraft(template: template).name : draft.name
                            ModuleTemplateCatalog.apply(template: template, to: &draft)
                        }
                        refreshValidation()
                    } label: {
                        HStack {
                            Text(template.title)
                            Spacer()
                            if draft.template == template {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var dataInspector: some View {
        AppPanel(title: "Data", subtitle: "승인된 데이터 소스만 사용할 수 있습니다.") {
            VStack(alignment: .leading, spacing: 12) {
                if draft.dataBindings.isEmpty {
                    Text("Data Binding이 없습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(draft.dataBindings) { binding in
                    dataBindingRow(binding)
                }
                Button {
                    update { $0.dataBindings.append(ModuleDataBinding(source: .tasks, scope: .currentProject, fieldRawValue: "title", aggregation: .list, limit: 3)) }
                    refreshValidation()
                } label: {
                    Label("Add Data Binding", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var componentsInspector: some View {
        AppPanel(title: "Components", subtitle: "최대 8개까지 조합할 수 있습니다.") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(sortedComponents) { component in
                    componentRow(component)
                }

                Menu {
                    ForEach(allowedComponentTypes) { type in
                        Button(type.rawValue.capitalized) { addComponent(type) }
                    }
                } label: {
                    Label("Add Component", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(draft.componentDefinitions.count >= 8)
            }
        }
    }

    private var actionsInspector: some View {
        AppPanel(title: "Actions", subtitle: "쓰기 Action은 권한과 확인을 거칩니다.") {
            VStack(alignment: .leading, spacing: 12) {
                if draft.actionDefinitions.isEmpty {
                    Text("Action이 없습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(draft.actionDefinitions) { action in
                    actionRow(action)
                }
                Menu {
                    ForEach(allowedActions) { action in
                        Button(action.title) { addAction(action) }
                    }
                } label: {
                    Label("Add Action", systemImage: "bolt")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var permissionsInspector: some View {
        AppPanel(title: "Permissions", subtitle: "Builder가 Data와 Action을 분석해 계산합니다.") {
            VStack(alignment: .leading, spacing: 10) {
                if validation.requestedCapabilities.isEmpty {
                    Text("요청 권한이 없습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(validation.requestedCapabilities) { request in
                        Toggle(isOn: capabilityBinding(request.capability)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(request.capability.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(request.reason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var previewInstallInspector: some View {
        AppPanel(title: "Preview & Install", subtitle: "Validation을 통과해야 설치할 수 있습니다.") {
            VStack(alignment: .leading, spacing: 12) {
                ModuleDraftPreviewCard(draft: draft)
                validationSummary
                Button("Save Draft") { saveDraft() }
                    .buttonStyle(.bordered)
                Button("Install Module") { install() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!validation.isInstallable)
                Button("Export .nouaemodule JSON") { exportModule() }
                    .buttonStyle(.bordered)
                if !exportText.isEmpty {
                    TextEditor(text: $exportText)
                        .font(.caption.monospaced())
                        .frame(minHeight: 130)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.18), lineWidth: 1))
                }
            }
        }
    }

    private var validationSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if validation.errors.isEmpty && validation.warnings.isEmpty {
                Label("Ready", systemImage: "checkmark.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
            ForEach(validation.errors, id: \.self) { error in
                Label(error, systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            ForEach(validation.warnings, id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var validation: ModuleValidationResult {
        stores.moduleBuilderStore.validate(draft, registry: stores.moduleRegistry)
    }

    private var statusText: String {
        if !validation.errors.isEmpty { return ModuleBuilderDraftState.invalid.rawValue }
        if draft.lastValidatedAt != nil { return ModuleBuilderDraftState.ready.rawValue }
        return ModuleBuilderDraftState.unsaved.rawValue
    }

    private var statusTone: StatusBadge.Tone {
        if !validation.errors.isEmpty { return .orange }
        if draft.lastValidatedAt != nil { return .green }
        return .neutral
    }

    private var allowedPlacements: [ModulePlacement] {
        [.dashboardCompact, .dashboardContext, .projectDashboardContext, .projectPageBlock, .projectNotesTool, .planQuickAction, .routineTemplate, .logPreset, .trackerMetric]
    }

    private var allowedComponentTypes: [ModuleComponentType] {
        [.text, .sectionHeader, .metric, .progress, .list, .checklist, .tagList, .activityDots, .compactChart, .button, .link, .divider, .noteInput, .toggle]
    }

    private var allowedActions: [ModuleActionBuilderType] {
        [.openCalendar, .openProjects, .openProject, .openPlan, .openLog, .createTask, .createLog, .createNote, .createRoutine, .createAdjustment, .markTaskTodo, .markTaskDoing, .markTaskDone, .completeReview, .enableRoutine, .disableRoutine]
    }

    private var sortedComponents: [ModuleComponentDefinition] {
        draft.componentDefinitions.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
    }

    private func dataBindingRow(_ binding: ModuleDataBinding) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(binding.source.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(binding.aggregation?.rawValue ?? "list")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Picker("Source", selection: Binding(get: { binding.source }, set: { source in updateBinding(binding.id) { $0.sourceRawValue = source.rawValue } })) {
                ForEach(ModuleDataSourceKind.allCases) { source in
                    Text(source.title).tag(source)
                }
            }
            Picker("Scope", selection: Binding(get: { binding.scope }, set: { scope in updateBinding(binding.id) { $0.scopeRawValue = scope.rawValue } })) {
                ForEach(ModuleDataScope.allCases) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            Stepper("Limit \(binding.limit ?? 3)", value: Binding(get: { binding.limit ?? 3 }, set: { value in updateBinding(binding.id) { $0.limit = min(max(value, 1), 10) } }), in: 1...10)
            Button("Remove", role: .destructive) {
                update { $0.dataBindings.removeAll { $0.id == binding.id } }
                refreshValidation()
            }
            .font(.caption)
        }
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func componentRow(_ component: ModuleComponentDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(component.type?.rawValue.capitalized ?? "Unknown")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button { moveComponent(component, delta: -1) } label: { Image(systemName: "arrow.up") }
                Button { moveComponent(component, delta: 1) } label: { Image(systemName: "arrow.down") }
            }
            TextField("Title", text: Binding(get: { component.title }, set: { value in updateComponent(component.id) { $0.title = value } }))
                .textFieldStyle(.roundedBorder)
            TextField("Value", text: Binding(get: { component.value }, set: { value in updateComponent(component.id) { $0.value = value } }))
                .textFieldStyle(.roundedBorder)
            if !draft.actionDefinitions.isEmpty {
                Picker("Action", selection: Binding(get: { component.actionId }, set: { actionId in updateComponent(component.id) { component in
                    component.actionId = actionId
                    component.actionRawValue = draft.actionDefinitions.first { $0.id == actionId }?.actionType.declarativeAction?.rawValue
                } })) {
                    Text("없음").tag(nil as UUID?)
                    ForEach(draft.actionDefinitions) { action in
                        Text(action.label).tag(action.id as UUID?)
                    }
                }
            }
            Button("Remove", role: .destructive) {
                update { $0.componentDefinitions.removeAll { $0.id == component.id } }
                refreshValidation()
            }
            .font(.caption)
        }
        .padding(10)
        .background(selectedComponentId == component.id ? Color.accentColor.opacity(0.10) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture { selectedComponentId = component.id }
    }

    private func actionRow(_ action: ModuleActionDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(action.actionType.title)
                .font(.subheadline.weight(.semibold))
            TextField("Label", text: Binding(get: { action.label }, set: { value in updateAction(action.id) { $0.label = value } }))
                .textFieldStyle(.roundedBorder)
            Toggle("Requires Confirmation", isOn: Binding(get: { action.requiresConfirmation }, set: { value in updateAction(action.id) { $0.requiresConfirmation = value } }))
            Button("Remove", role: .destructive) {
                update {
                    $0.actionDefinitions.removeAll { $0.id == action.id }
                    for index in $0.componentDefinitions.indices where $0.componentDefinitions[index].actionId == action.id {
                        $0.componentDefinitions[index].actionId = nil
                        $0.componentDefinitions[index].actionRawValue = nil
                    }
                }
                refreshValidation()
            }
            .font(.caption)
        }
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private func binding(_ keyPath: WritableKeyPath<ModuleBuilderDraft, String>) -> Binding<String> {
        Binding(
            get: { draft[keyPath: keyPath] },
            set: { value in update { $0[keyPath: keyPath] = value } }
        )
    }

    private func update(_ mutation: (inout ModuleBuilderDraft) -> Void) {
        history.append(draft)
        if history.count > 20 { history.removeFirst() }
        redoStack.removeAll()
        mutation(&draft)
        draft.updatedAt = Date()
        refreshValidation()
    }

    private func updateBinding(_ id: UUID, mutate: (inout ModuleDataBinding) -> Void) {
        update { draft in
            guard let index = draft.dataBindings.firstIndex(where: { $0.id == id }) else { return }
            mutate(&draft.dataBindings[index])
        }
    }

    private func updateComponent(_ id: UUID, mutate: (inout ModuleComponentDefinition) -> Void) {
        update { draft in
            guard let index = draft.componentDefinitions.firstIndex(where: { $0.id == id }) else { return }
            mutate(&draft.componentDefinitions[index])
        }
    }

    private func updateAction(_ id: UUID, mutate: (inout ModuleActionDefinition) -> Void) {
        update { draft in
            guard let index = draft.actionDefinitions.firstIndex(where: { $0.id == id }) else { return }
            mutate(&draft.actionDefinitions[index])
        }
    }

    private func addComponent(_ type: ModuleComponentType) {
        update {
            $0.componentDefinitions.append(ModuleComponentDefinition(type: type, title: type.rawValue.capitalized, value: defaultValue(for: type), order: $0.componentDefinitions.count))
        }
    }

    private func addAction(_ actionType: ModuleActionBuilderType) {
        update {
            $0.actionDefinitions.append(ModuleActionDefinition(actionType: actionType, label: actionType.title, iconSystemName: "bolt", requiresConfirmation: actionType.declarativeAction != .openDestination, order: $0.actionDefinitions.count))
        }
    }

    private func moveComponent(_ component: ModuleComponentDefinition, delta: Int) {
        update { draft in
            guard let index = draft.componentDefinitions.firstIndex(where: { $0.id == component.id }) else { return }
            let target = max(0, min(draft.componentDefinitions.count - 1, index + delta))
            guard target != index else { return }
            draft.componentDefinitions.swapAt(index, target)
            for itemIndex in draft.componentDefinitions.indices {
                draft.componentDefinitions[itemIndex].order = itemIndex
            }
        }
    }

    private func defaultValue(for type: ModuleComponentType) -> String {
        switch type {
        case .metric: return "0"
        case .progress: return "0.5"
        case .tagList: return "Focus,Review,Next"
        case .button: return "Run"
        default: return ""
        }
    }

    private func refreshValidation() {
        let capabilities = validation.requestedCapabilities.map(\.capability)
        draft.setRequestedCapabilities(capabilities)
        if approvedCapabilityRawValues.isEmpty {
            approvedCapabilityRawValues = Set(capabilities.map(\.rawValue))
        } else {
            approvedCapabilityRawValues = approvedCapabilityRawValues.intersection(Set(capabilities.map(\.rawValue))).union(Set(capabilities.filter { capability in
                !approvedCapabilityRawValues.contains(capability.rawValue)
            }.map(\.rawValue)))
        }
    }

    private func saveDraft() {
        do {
            draft.lastValidatedAt = validation.isInstallable ? Date() : nil
            try stores.moduleBuilderStore.saveDraft(draft)
            message = "Draft를 저장했습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func install() {
        do {
            let requiredCapabilities = Set(validation.requestedCapabilities.filter(\.isRequired).map { $0.capability.rawValue })
            guard requiredCapabilities.isSubset(of: approvedCapabilityRawValues) else {
                message = "필수 권한을 모두 승인해야 설치할 수 있습니다."
                return
            }
            let capabilities = validation.requestedCapabilities.map(\.capability).filter { approvedCapabilityRawValues.contains($0.rawValue) }
            _ = try stores.moduleBuilderStore.install(draft, registry: stores.moduleRegistry, grantedCapabilities: capabilities)
            message = "Module을 설치했습니다."
            dismiss()
        } catch {
            message = error.localizedDescription
        }
    }

    private func exportModule() {
        do {
            var exportDraft = draft
            exportDraft.setRequestedCapabilities(validation.requestedCapabilities.map(\.capability))
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(ModuleBuilderExportPayload(draft: exportDraft))
            exportText = String(data: data, encoding: .utf8) ?? ""
            message = ".nouaemodule JSON을 생성했습니다. Import 화면에서 다시 검증할 수 있습니다."
        } catch {
            message = error.localizedDescription
        }
    }

    private func undo() {
        guard let previous = history.popLast() else { return }
        redoStack.append(draft)
        draft = previous
        refreshValidation()
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        history.append(draft)
        draft = next
        refreshValidation()
    }
}

private struct ModuleDraftPreviewCard: View {
    let draft: ModuleBuilderDraft

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(draft.name.isEmpty ? "Untitled Module" : draft.name, systemImage: draft.iconSystemName.isEmpty ? "square.grid.2x2" : draft.iconSystemName)
                    .font(.subheadline.weight(.semibold))
                if !draft.descriptionText.isEmpty {
                    Text(draft.descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(draft.componentDefinitions.sorted { ($0.order ?? 0) < ($1.order ?? 0) }.prefix(8)) { component in
                    preview(component)
                }
            }
        }
    }

    private func preview(_ component: ModuleComponentDefinition) -> some View {
        Group {
            switch component.type {
            case .sectionHeader:
                Text(component.title).font(.headline)
            case .metric:
                HStack { Text(component.title).foregroundStyle(.secondary); Spacer(); Text(component.value.isEmpty ? "0" : component.value).font(.headline) }
            case .progress:
                VStack(alignment: .leading, spacing: 5) {
                    Text(component.title).font(.caption)
                    ProgressView(value: min(max(Double(component.value) ?? 0.5, 0), 1))
                }
            case .button:
                Button(component.title.isEmpty ? "Run" : component.title) {}
                    .buttonStyle(.bordered)
                    .disabled(true)
            case .divider:
                AppDivider()
            case .activityDots, .compactChart:
                HStack(spacing: 4) { ForEach(0..<7, id: \.self) { index in Circle().fill(index % 2 == 0 ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.2)).frame(width: 8, height: 8) } }
            case .tagList:
                HStack(spacing: 6) {
                    ForEach(component.value.split(separator: ",").map(String.init).prefix(6), id: \.self) { tag in
                        Text(tag).font(.caption2).padding(.horizontal, 8).padding(.vertical, 4).background(Color.secondary.opacity(0.12), in: Capsule())
                    }
                }
            case .list, .checklist:
                VStack(alignment: .leading, spacing: 4) {
                    Text(component.title).font(.caption.weight(.semibold))
                    Text("Preview item").font(.caption).foregroundStyle(.secondary)
                    Text("Preview item").font(.caption).foregroundStyle(.secondary)
                }
            default:
                Text(component.value.isEmpty ? component.title : component.value)
                    .font(.subheadline)
            }
        }
    }
}
