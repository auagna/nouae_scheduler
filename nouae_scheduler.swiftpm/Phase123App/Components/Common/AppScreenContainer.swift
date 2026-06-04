import SwiftUI

enum AppUI {
    enum Spacing {
        static let card: CGFloat = 12
        static let section: CGFloat = 24
        static let pageHeaderBottom: CGFloat = 20
        static let rowVertical: CGFloat = 11
        static let cardPadding: CGFloat = 16
    }

    enum Radius {
        static let card: CGFloat = 16
        static let panel: CGFloat = 18
    }

    static func screenHorizontalPadding(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .compact ? 16 : 28
    }

    static var separatorColor: Color {
        Color.secondary.opacity(0.15)
    }
}

struct AppScreenContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let scrolls: Bool
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    private let content: () -> Content

    init(
        scrolls: Bool = true,
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = AppUI.Spacing.section,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.scrolls = scrolls
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        Group {
            if scrolls {
                ScrollView {
                    contentStack
                }
            } else {
                contentStack
            }
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    private var contentStack: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
        .padding(.horizontal, AppUI.screenHorizontalPadding(horizontalSizeClass: horizontalSizeClass))
        .padding(.vertical, 20)
    }
}
