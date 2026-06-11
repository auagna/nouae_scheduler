import SwiftData
import SwiftUI
import UIKit

struct PromptExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ProjectArea.updatedAt, order: .reverse) private var areas: [ProjectArea]
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \RawTask.createdAt, order: .reverse) private var rawTasks: [RawTask]
    @Query(sort: \WorkBlock.startAt, order: .reverse) private var workBlocks: [WorkBlock]
    @Query(sort: \ProjectNote.updatedAt, order: .reverse) private var notes: [ProjectNote]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]
    @Query(sort: \NextAdjustment.createdAt, order: .reverse) private var adjustments: [NextAdjustment]

    @State private var promptType: PromptExportType
    @State private var selectedProjectId: UUID?
    @State private var copiedMessage: String?

    private let builder = PromptBuilderService()

    init(initialType: PromptExportType = .weeklyReview, selectedProjectId: UUID? = nil) {
        _promptType = State(initialValue: initialType)
        _selectedProjectId = State(initialValue: selectedProjectId)
    }

    var body: some View {
        NavigationStack {
            AppScreenContainer(spacing: 16) {
                AppPageHeader(title: "Prompt Export", subtitle: "AI API 없이 분석 프롬프트를 생성하고 복사합니다.") {
                    Button("Done") { dismiss() }
                        .buttonStyle(.bordered)
                }

                AppPanel(title: "Prompt Type", subtitle: "분석 목적을 선택합니다.") {
                    Picker("Prompt Type", selection: $promptType) {
                        ForEach(PromptExportType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Project Scope", selection: $selectedProjectId) {
                        Text("전체 운영").tag(nil as UUID?)
                        ForEach(projects) { project in
                            Text(project.title).tag(project.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)

                    Text("실제 AI 호출은 하지 않습니다. 복사한 뒤 ChatGPT / Claude / Gemini 등에 직접 붙여넣어 사용합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let copiedMessage {
                    Text(copiedMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                PromptPreviewCard(prompt: promptText) {
                    UIPasteboard.general.string = promptText
                    copiedMessage = "Prompt를 클립보드에 복사했습니다."
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var promptText: String {
        builder.build(
            type: promptType,
            selectedProjectId: selectedProjectId,
            areas: areas,
            projects: projects,
            rawTasks: rawTasks,
            workBlocks: workBlocks,
            notes: notes,
            logs: logs,
            adjustments: adjustments
        )
    }
}
