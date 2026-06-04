import SwiftUI

struct IntelligencePanel: View {
    let insights: [DashboardInsight]
    let attentionItems: [String]

    var body: some View {
        AppPanel(title: "Intelligence", subtitle: "패턴과 조정") {
            VStack(alignment: .leading, spacing: AppUI.Spacing.card) {
                ForEach(insights) { insight in
                    InsightPreviewCard(insight: insight)
                }
                AttentionCard(items: attentionItems)
            }
        }
    }
}

struct InsightPreviewCard: View {
    let insight: DashboardInsight

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 7) {
                StatusBadge(insight.type, tone: tone)
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var tone: StatusBadge.Tone {
        switch insight.type {
        case "Blind Spot": return .orange
        case "Adjustment": return .blue
        case "Pattern": return .purple
        case "Opportunity": return .green
        default: return .neutral
        }
    }
}

private struct AttentionCard: View {
    let items: [String]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                AppSectionHeader(title: "Attention", subtitle: "오늘 확인할 항목")
                    .padding(.bottom, 6)
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    AppListRow(
                        title: item,
                        subtitle: nil,
                        showsSeparator: index < items.count - 1
                    ) {
                        Image(systemName: "smallcircle.filled.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
}
