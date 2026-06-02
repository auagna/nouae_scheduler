import SwiftData
import SwiftUI

struct ProjectDashboardView: View {
    let project: Project
    @EnvironmentObject private var stores: AppStores
    @Query private var blocks: [WorkBlock]
    @Query(sort: \ProjectLog.createdAt, order: .reverse) private var logs: [ProjectLog]

    var body: some View {
        List {
            Section { ProjectDashboardHeader(project: project, onChangeStatus: changeStatus) }
            Section("Summary") { ProjectSummaryPanel(project: project, blocks: projectBlocks, recentLog: projectLogs.first) }
            ProjectInboxSection(project: project)
            ProjectTodayWorkSection(project: project)
            ProjectMemoSectionView(project: project)
            ProjectNextAdjustmentSection(project: project)
            ProjectRecentLogSection(project: project)
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var projectBlocks: [WorkBlock] { blocks.filter { $0.projectId == project.id } }
    private var projectLogs: [ProjectLog] { logs.filter { $0.projectId == project.id } }
    private func changeStatus(_ status: ProjectStatus) { try? stores.projectStore.updateProjectStatus(project: project, status: status) }
}
