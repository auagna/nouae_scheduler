import SwiftUI

struct CalendarCanvasView: View {
    @Binding var selectedDate: Date
    let items: [CalendarTimelineItem]
    let projects: [Project]
    let isDrawingMode: Bool
    let onSelectDay: (Date) -> Void
    let onSelectEvent: (CalendarTimelineItem) -> Void

    @State private var drawingData: Data = Data()

    private var drawingKey: String {
        "nouae.calendar.drawing.\(selectedDate.formatted(.dateTime.year().month(.twoDigits)))"
    }

    var body: some View {
        AppPanel(title: "Canvas", subtitle: "Scroll and annotate the month flow") {
            ZStack {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    CalendarCanvasGrid(
                        selectedDate: selectedDate,
                        items: items,
                        zoomScale: 1,
                        onSelectDay: onSelectDay,
                        onSelectEvent: onSelectEvent
                    )
                    .frame(minWidth: 760, minHeight: 560)
                    .padding(10)
                }
                .scrollDisabled(isDrawingMode)
                .allowsHitTesting(!isDrawingMode)

                if isDrawingMode {
                    CalendarDrawingOverlay(data: $drawingData)
                        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card, style: .continuous))
                        .transition(.opacity)
                        .allowsHitTesting(true)
                }
            }
            .frame(minHeight: 560)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: AppUI.Radius.card, style: .continuous))
            .overlay(alignment: .topTrailing) {
                StatusBadge(modeLabel, tone: .blue, symbolName: isDrawingMode ? "pencil.tip" : "hand.draw")
                    .padding(12)
            }
            .onAppear { loadDrawing() }
            .onChange(of: selectedDate) { _, _ in loadDrawing() }
            .onChange(of: drawingData) { _, _ in saveDrawing() }
        }
    }

    private var modeLabel: String {
        if isDrawingMode { return "Drawing Mode" }
        return "Scroll Mode"
    }

    private func loadDrawing() {
        drawingData = UserDefaults.standard.data(forKey: drawingKey) ?? Data()
    }

    private func saveDrawing() {
        UserDefaults.standard.set(drawingData, forKey: drawingKey)
    }
}
