import SwiftUI

struct AppDivider: View {
    let inset: CGFloat

    init(inset: CGFloat = 0) {
        self.inset = inset
    }

    var body: some View {
        Rectangle()
            .fill(AppUI.separatorColor)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}
