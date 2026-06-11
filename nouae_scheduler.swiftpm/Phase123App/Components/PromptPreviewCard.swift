import SwiftUI

struct PromptPreviewCard: View {
    let prompt: String
    let onCopy: () -> Void

    var body: some View {
        AppPanel(title: "Prompt Preview", subtitle: "복사 전에 포함될 내용을 확인합니다.") {
            HStack {
                Text("\(prompt.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    onCopy()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
            }

            AppDivider()

            ScrollView {
                Text(prompt)
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(minHeight: 280)
            .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
