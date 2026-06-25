import Foundation
import SwiftData

@MainActor
final class ModuleBuilderStore {
    private let context: ModelContext
    private let validator: ModuleBuilderValidator

    init(context: ModelContext) {
        self.context = context
        validator = ModuleBuilderValidator()
    }

    func newDraft(template: ModuleBuilderTemplate = .blank) -> ModuleBuilderDraft {
        ModuleTemplateCatalog.makeDraft(template: template)
    }

    func saveDraft(_ draft: ModuleBuilderDraft) throws {
        var updated = draft
        updated.updatedAt = Date()
        let data = try JSONEncoder().encode(updated)
        let records = try context.fetch(FetchDescriptor<ModuleDraftRecord>())
        if let existing = records.first(where: { $0.id == updated.id }) {
            existing.draftData = data
            existing.name = updated.name.isEmpty ? "Untitled Module" : updated.name
            existing.updatedAt = Date()
        } else {
            context.insert(ModuleDraftRecord(id: updated.id, draftData: data, name: updated.name.isEmpty ? "Untitled Module" : updated.name))
        }
        try context.save()
    }

    func archiveDraft(_ record: ModuleDraftRecord) throws {
        record.archivedAt = Date()
        record.updatedAt = Date()
        try context.save()
    }

    func duplicateDraft(_ draft: ModuleBuilderDraft) -> ModuleBuilderDraft {
        var copy = draft
        copy.id = UUID()
        copy.moduleIdentifier = "user.module.\(UUID().uuidString)"
        copy.name = draft.name.isEmpty ? "Module Copy" : "\(draft.name) Copy"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.lastValidatedAt = nil
        return copy
    }

    func validate(_ draft: ModuleBuilderDraft, registry: ModuleRegistry) -> ModuleValidationResult {
        validator.validate(draft, registry: registry)
    }

    @discardableResult
    func install(_ draft: ModuleBuilderDraft, registry: ModuleRegistry, grantedCapabilities: [ModuleCapability]) throws -> ModuleInstance {
        var installDraft = draft
        let result = validator.validate(installDraft, registry: registry)
        guard result.isInstallable else {
            throw ModuleError.invalidManifest(result.errors.joined(separator: "\n"))
        }
        installDraft.setRequestedCapabilities(result.requestedCapabilities.map(\.capability))
        installDraft.lastValidatedAt = Date()

        let manifest = installDraft.manifest()
        let instance = try registry.installModule(manifest, placement: installDraft.placement, context: context)
        instance.configurationData = try installDraft.configurationData()
        instance.updatedAt = Date()
        let grants = try context.fetch(FetchDescriptor<ModulePermissionGrant>())
        for grant in grants where grant.moduleIdentifier == manifest.id {
            let shouldGrant = grantedCapabilities.contains(grant.capability)
            grant.isGranted = shouldGrant
            grant.grantedAt = shouldGrant ? Date() : grant.grantedAt
            grant.revokedAt = shouldGrant ? nil : Date()
            grant.updatedAt = Date()
        }
        try context.save()
        try saveDraft(installDraft)
        return instance
    }
}

@MainActor
struct ModuleBuilderValidator {
    func validate(_ draft: ModuleBuilderDraft, registry: ModuleRegistry) -> ModuleValidationResult {
        var errors: [String] = []
        var warnings: [String] = []

        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Module 이름을 입력하세요.")
        }
        if draft.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            warnings.append("설명이 비어 있습니다.")
        }
        if draft.componentDefinitions.isEmpty {
            errors.append("Component를 최소 1개 추가하세요.")
        }
        if draft.componentDefinitions.count > 8 {
            errors.append("Component는 최대 8개까지 허용됩니다.")
        }
        if draft.componentDefinitions.contains(where: { $0.type == nil }) {
            errors.append("지원하지 않는 Component가 있습니다.")
        }
        if draft.componentDefinitions.contains(where: { $0.children.count > 10 }) {
            errors.append("List / Checklist 항목은 최대 10개까지 표시합니다.")
        }
        if draft.actionDefinitions.contains(where: { !$0.requiresConfirmation && requiresConfirmation($0.actionType) }) {
            warnings.append("쓰기 Action은 사용자 확인을 권장합니다.")
        }
        if let existing = registry.module(for: draft.moduleIdentifier), existing.origin != .user {
            errors.append("Built-in Module identifier와 중복됩니다.")
        }

        let capabilities = deriveCapabilities(from: draft)
        if capabilities.contains(where: \.isForbidden) {
            errors.append("금지 Capability가 포함되어 있습니다.")
        }

        let requests = capabilities.map {
            ModuleCapabilityRequest(capability: $0, isRequired: true, reason: reason(for: $0))
        }

        return ModuleValidationResult(errors: errors, warnings: warnings, requestedCapabilities: requests)
    }

    func deriveCapabilities(from draft: ModuleBuilderDraft) -> [ModuleCapability] {
        var values = Set<ModuleCapability>()

        for binding in draft.dataBindings {
            switch binding.source {
            case .areas, .currentArea: values.insert(.readAreas)
            case .projects, .currentProject: values.insert(.readProjects)
            case .tasks: values.insert(.readTasks)
            case .workBlocks: values.insert(.readWorkBlocks)
            case .logs: values.insert(.readLogs)
            case .projectNotes: values.insert(.readNotes)
            case .routines, .routineOccurrences: values.insert(.readRoutines)
            case .trackerSummary: values.insert(.readTrackerSummary)
            case .nextAdjustments: values.insert(.readProjects)
            case .currentDate, .staticData: break
            }
        }

        for action in draft.actionDefinitions {
            switch action.actionType {
            case .createTask: values.insert(.createTask)
            case .createLog: values.insert(.createLog)
            case .createNote: values.insert(.createNote)
            case .createRoutine: values.insert(.createRoutine)
            case .createAdjustment: values.insert(.createAdjustment)
            case .openProject: values.insert(.openProject)
            case .openPlan: values.insert(.openPlan)
            case .openCalendar: values.insert(.openCalendar)
            case .openLog: values.insert(.openLog)
            case .openDashboard, .openProjects, .openRoutine, .openProjectNotes, .openProjectPage:
                break
            case .markTaskTodo, .markTaskDoing, .markTaskDone, .completeReview:
                values.insert(.updateTask)
            case .enableRoutine, .disableRoutine:
                values.insert(.createRoutine)
            }
        }

        return values.sorted { $0.rawValue < $1.rawValue }
    }

    private func requiresConfirmation(_ action: ModuleActionBuilderType) -> Bool {
        switch action {
        case .createTask, .createLog, .createNote, .createRoutine, .createAdjustment, .markTaskTodo, .markTaskDoing, .markTaskDone, .completeReview, .enableRoutine, .disableRoutine:
            return true
        default:
            return false
        }
    }

    private func reason(for capability: ModuleCapability) -> String {
        switch capability {
        case .readTasks: return "Task 기반 목록이나 metric을 표시합니다."
        case .readWorkBlocks: return "WorkBlock 시간/완료 정보를 표시합니다."
        case .readLogs: return "최근 Log나 reflection 정보를 표시합니다."
        case .readNotes: return "Project Note 정보를 표시합니다."
        case .readRoutines: return "Routine 진행률과 템플릿 정보를 표시합니다."
        case .readProjects: return "Project context를 기준으로 필터링합니다."
        case .readAreas: return "Area context를 기준으로 필터링합니다."
        case .readTrackerSummary: return "Tracker 요약을 표시합니다."
        case .createTask: return "버튼으로 RawTask를 생성합니다."
        case .createLog: return "버튼으로 Log 초안을 생성합니다."
        case .createNote: return "버튼으로 Note 생성을 요청합니다."
        case .createRoutine: return "Routine 생성 또는 조정을 요청합니다."
        case .createAdjustment: return "Next Adjustment 생성을 요청합니다."
        default: return "Module 동작에 필요합니다."
        }
    }
}

enum ModuleTemplateCatalog {
    static var templates: [ModuleBuilderTemplate] {
        ModuleBuilderTemplate.allCases
    }

    static func makeDraft(template: ModuleBuilderTemplate) -> ModuleBuilderDraft {
        var draft = ModuleBuilderDraft(template: template)
        draft.name = defaultName(for: template)
        draft.descriptionText = defaultDescription(for: template)
        draft.category = defaultCategory(for: template)
        draft.placement = defaultPlacement(for: template)
        draft.iconSystemName = defaultIcon(for: template)
        apply(template: template, to: &draft)
        return draft
    }

    static func apply(template: ModuleBuilderTemplate, to draft: inout ModuleBuilderDraft) {
        draft.template = template
        switch template {
        case .blank:
            draft.componentDefinitions = []
            draft.dataBindings = []
            draft.actionDefinitions = []
        case .metricCard:
            let binding = ModuleDataBinding(source: .workBlocks, scope: .global, fieldRawValue: "duration", aggregation: .sumDuration, dateRange: .thisWeek)
            draft.dataBindings = [binding]
            draft.componentDefinitions = [
                ModuleComponentDefinition(type: .sectionHeader, title: "이번 주 작업 시간", order: 0),
                ModuleComponentDefinition(type: .metric, title: "WorkBlocks", value: "이번 주", dataBindingId: binding.id, order: 1),
                ModuleComponentDefinition(type: .text, title: "Plan에 배치된 실행 시간이 누적됩니다.", order: 2)
            ]
            draft.actionDefinitions = []
        case .listCard:
            let binding = ModuleDataBinding(source: .tasks, scope: .currentProject, fieldRawValue: "title", aggregation: .list, limit: 3)
            let action = ModuleActionDefinition(actionType: .openPlan, label: "Open Plan", iconSystemName: "calendar")
            draft.dataBindings = [binding]
            draft.actionDefinitions = [action]
            draft.componentDefinitions = [
                ModuleComponentDefinition(type: .sectionHeader, title: "다음 Task 3개", order: 0),
                ModuleComponentDefinition(type: .list, title: "Tasks", dataBindingId: binding.id, order: 1, children: [
                    ModuleComponentDefinition(type: .text, title: "Task preview", order: 0),
                    ModuleComponentDefinition(type: .text, title: "Task preview", order: 1)
                ]),
                ModuleComponentDefinition(type: .button, title: action.label, actionId: action.id, action: action.actionType.declarativeAction, order: 2)
            ]
        case .progressCard:
            let binding = ModuleDataBinding(source: .workBlocks, scope: .currentProject, fieldRawValue: "completion", aggregation: .completionRate, dateRange: .thisWeek)
            draft.dataBindings = [binding]
            draft.componentDefinitions = [
                ModuleComponentDefinition(type: .sectionHeader, title: "진행률", order: 0),
                ModuleComponentDefinition(type: .progress, title: "Completion", value: "0.45", dataBindingId: binding.id, order: 1),
                ModuleComponentDefinition(type: .metric, title: "완료율", value: "45%", order: 2)
            ]
            draft.actionDefinitions = []
        case .quickAction:
            let action = ModuleActionDefinition(actionType: .createTask, label: "빠른 Task 생성", iconSystemName: "plus", requiresConfirmation: true)
            draft.dataBindings = []
            draft.actionDefinitions = [action]
            draft.componentDefinitions = [
                ModuleComponentDefinition(type: .text, title: "필요한 행동을 바로 Capture합니다.", order: 0),
                ModuleComponentDefinition(type: .button, title: action.label, actionId: action.id, action: action.actionType.declarativeAction, order: 1)
            ]
        case .logPreset:
            let action = ModuleActionDefinition(actionType: .createLog, label: "Log 작성", iconSystemName: "square.and.pencil", requiresConfirmation: true)
            draft.placement = .logPreset
            draft.dataBindings = []
            draft.actionDefinitions = [action]
            draft.componentDefinitions = [
                ModuleComponentDefinition(type: .sectionHeader, title: "작업 종료 회고", order: 0),
                ModuleComponentDefinition(type: .text, title: "실제로 무엇이 진행됐고 무엇이 막혔나?", order: 1),
                ModuleComponentDefinition(type: .button, title: action.label, actionId: action.id, action: action.actionType.declarativeAction, order: 2)
            ]
        case .routineTemplate:
            let action = ModuleActionDefinition(actionType: .createRoutine, label: "Routine Editor 열기", iconSystemName: "repeat", requiresConfirmation: true)
            draft.placement = .routineTemplate
            draft.dataBindings = [ModuleDataBinding(source: .routines, scope: .global, fieldRawValue: "completion", aggregation: .completionRate, dateRange: .thisWeek)]
            draft.actionDefinitions = [action]
            draft.componentDefinitions = [
                ModuleComponentDefinition(type: .sectionHeader, title: "Routine Template", order: 0),
                ModuleComponentDefinition(type: .progress, title: "이번 주 Routine", value: "0.3", order: 1),
                ModuleComponentDefinition(type: .button, title: action.label, actionId: action.id, action: action.actionType.declarativeAction, order: 2)
            ]
        case .projectSummary:
            let binding = ModuleDataBinding(source: .workBlocks, scope: .currentProject, fieldRawValue: "completion", aggregation: .completionRate, dateRange: .thisWeek)
            draft.placement = .projectDashboardContext
            draft.dataBindings = [binding]
            draft.actionDefinitions = []
            draft.componentDefinitions = [
                ModuleComponentDefinition(type: .sectionHeader, title: "Project 진행 요약", order: 0),
                ModuleComponentDefinition(type: .metric, title: "이번 주 WorkBlocks", value: "Project context", dataBindingId: binding.id, order: 1),
                ModuleComponentDefinition(type: .activityDots, title: "최근 활동", order: 2)
            ]
        }
    }

    private static func defaultName(for template: ModuleBuilderTemplate) -> String {
        switch template {
        case .blank: return "New Module"
        case .metricCard: return "이번 주 작업 시간"
        case .listCard: return "다음 Task 3개"
        case .progressCard: return "진행률 카드"
        case .quickAction: return "빠른 RawTask"
        case .logPreset: return "Quick Log Preset"
        case .routineTemplate: return "Routine 완료율"
        case .projectSummary: return "Project 진행 요약"
        }
    }

    private static func defaultDescription(for template: ModuleBuilderTemplate) -> String {
        switch template {
        case .blank: return "내 운영 흐름에 맞는 작은 Module입니다."
        case .metricCard: return "선택한 기간의 metric을 표시합니다."
        case .listCard: return "다음에 볼 항목을 짧게 표시합니다."
        case .progressCard: return "진행률을 조용하게 보여줍니다."
        case .quickAction: return "자주 쓰는 행동을 가까이에 둡니다."
        case .logPreset: return "짧은 회고를 빠르게 시작합니다."
        case .routineTemplate: return "반복 가능한 Routine 흐름을 보여줍니다."
        case .projectSummary: return "Project context 요약을 표시합니다."
        }
    }

    private static func defaultCategory(for template: ModuleBuilderTemplate) -> ModuleCategory {
        switch template {
        case .metricCard, .progressCard, .projectSummary: return .tracker
        case .listCard, .quickAction: return .planning
        case .logPreset: return .reflection
        case .routineTemplate: return .routine
        case .blank: return .utility
        }
    }

    private static func defaultPlacement(for template: ModuleBuilderTemplate) -> ModulePlacement {
        switch template {
        case .metricCard, .progressCard: return .dashboardCompact
        case .listCard, .projectSummary: return .projectDashboardContext
        case .quickAction: return .planQuickAction
        case .logPreset: return .logPreset
        case .routineTemplate: return .routineTemplate
        case .blank: return .dashboardCompact
        }
    }

    private static func defaultIcon(for template: ModuleBuilderTemplate) -> String {
        switch template {
        case .metricCard: return "chart.bar"
        case .listCard: return "list.bullet"
        case .progressCard: return "gauge.with.dots.needle.50percent"
        case .quickAction: return "bolt"
        case .logPreset: return "square.and.pencil"
        case .routineTemplate: return "repeat.circle"
        case .projectSummary: return "folder.badge.gearshape"
        case .blank: return "square.grid.2x2"
        }
    }
}
