import SwiftUI

struct AppListRow<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let showsSeparator: Bool
    private let leading: () -> Leading
    private let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        showsSeparator: Bool = true,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsSeparator = showsSeparator
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                leading()
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 8)
                trailing()
                    .font(.caption)
            }
            .frame(minHeight: 44)
            .padding(.vertical, AppUI.Spacing.rowVertical)

            if showsSeparator {
                AppDivider(inset: 40)
            }
        }
    }
}

extension AppListRow where Leading == EmptyView, Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, showsSeparator: Bool = true) {
        self.init(title: title, subtitle: subtitle, showsSeparator: showsSeparator) {
            EmptyView()
        } trailing: {
            EmptyView()
        }
    }
}

extension AppListRow where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        showsSeparator: Bool = true,
        @ViewBuilder leading: @escaping () -> Leading
    ) {
        self.init(title: title, subtitle: subtitle, showsSeparator: showsSeparator, leading: leading) {
            EmptyView()
        }
    }
}
