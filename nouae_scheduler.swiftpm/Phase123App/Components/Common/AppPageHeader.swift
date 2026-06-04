import SwiftUI

struct AppPageHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    private let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)
            trailing()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, AppUI.Spacing.pageHeaderBottom)
    }
}

extension AppPageHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) {
            EmptyView()
        }
    }
}
