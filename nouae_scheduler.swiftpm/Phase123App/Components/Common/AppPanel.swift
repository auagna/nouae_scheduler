import SwiftUI

struct AppPanel<Content: View>: View {
    let title: String
    let subtitle: String?
    private let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.card) {
            AppSectionHeader(title: title, subtitle: subtitle)
            AppDivider()
            content()
        }
        .padding(AppUI.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.panel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppUI.Radius.panel, style: .continuous)
                .stroke(AppUI.separatorColor, lineWidth: 1)
        }
    }
}
