import SwiftUI

struct AppCard<Content: View>: View {
    private let padding: CGFloat
    private let usesMaterial: Bool
    private let content: () -> Content

    init(
        padding: CGFloat = AppUI.Spacing.cardPadding,
        usesMaterial: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.usesMaterial = usesMaterial
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppUI.Radius.card, style: .continuous)
                    .stroke(AppUI.separatorColor, lineWidth: 1)
            }
    }

    @ViewBuilder
    private var background: some View {
        if usesMaterial {
            Rectangle().fill(.regularMaterial)
        } else {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}
