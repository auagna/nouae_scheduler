import SwiftData
import SwiftUI

private enum ProjectPageMode: String, CaseIterable, Identifiable {
    case board = "Board"
    case notes = "Notes"
    case gallery = "Gallery"
    case sketch = "Sketch"

    var id: String { rawValue }
}

struct ProjectPageView: View {
    let project: Project

    @EnvironmentObject private var stores: AppStores
    @Query(sort: \ProjectBoardItem.updatedAt, order: .reverse) private var boardItems: [ProjectBoardItem]
    @Query(sort: \ProjectNote.updatedAt, order: .reverse) private var notes: [ProjectNote]

    @State private var mode: ProjectPageMode = .board
    @State private var showingAddItem = false
    @State private var message: String?

    var body: some View {
        AppScreenContainer(spacing: 16) {
            AppPageHeader(
                title: "Project Page",
                subtitle: "\(project.title)의 moodboard / vision board"
            ) {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Add Board Item")
            }

            Picker("Project Page Mode", selection: $mode) {
                ForEach(ProjectPageMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ModuleHostView(placement: .projectPageBlock, projectId: project.id, layoutStyle: .regular)

            content
        }
        .navigationTitle("Project Page")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddItem) {
            AddBoardItemSheet(project: project) { type, title, content, url, colorHex in
                save(type: type, title: title, content: content, url: url, colorHex: colorHex)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .board:
            boardPanel(title: "Moodboard", subtitle: "reference, quote, material, experiment")
        case .notes:
            notesPanel
        case .gallery:
            boardPanel(title: "Gallery", subtitle: "image, color, material, output", filter: [.image, .color, .material, .output])
        case .sketch:
            boardPanel(title: "Sketch", subtitle: "sketch와 시각적 아이디어", filter: [.sketch])
        }
    }

    private func boardPanel(title: String, subtitle: String, filter: Set<ProjectBoardItemType>? = nil) -> some View {
        let visibleItems = filteredBoardItems(filter: filter)
        return AppPanel(title: title, subtitle: subtitle) {
            if visibleItems.isEmpty {
                ContentUnavailableView("Board item이 없습니다", systemImage: "square.grid.2x2", description: Text("오른쪽 위 + 버튼으로 reference나 note를 추가하세요."))
                    .frame(maxWidth: .infinity)
            } else {
                ProjectVisionBoardView(project: project, items: visibleItems)
            }
        }
    }

    private var notesPanel: some View {
        AppPanel(title: "Project Notes", subtitle: "Project 내부 노트북") {
            let projectNotes = notes.filter { $0.projectId == project.id && !$0.isArchived }
            if projectNotes.isEmpty {
                ContentUnavailableView("Project Note가 없습니다", systemImage: "book.closed", description: Text("Projects 탭의 Notes View에서 기본 노트를 만들 수 있습니다."))
                    .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(projectNotes.prefix(8)) { note in
                        AppListRow(title: note.title, subtitle: note.noteType.title) {
                            Image(systemName: note.noteType.symbolName)
                                .foregroundStyle(.secondary)
                        } trailing: {
                            Text(note.updatedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func filteredBoardItems(filter: Set<ProjectBoardItemType>?) -> [ProjectBoardItem] {
        let scoped = boardItems.filter { $0.projectId == project.id && !$0.isArchived }
        guard let filter else { return scoped }
        return scoped.filter { filter.contains($0.itemType) }
    }

    private func save(type: ProjectBoardItemType, title: String, content: String, url: String, colorHex: String?) {
        do {
            _ = try stores.projectBoardStore.createItem(
                projectId: project.id,
                type: type,
                title: title,
                content: content,
                url: url,
                colorHex: colorHex
            )
            message = "Project Page에 추가했습니다."
        } catch {
            message = error.localizedDescription
        }
    }
}
