import SwiftUI

struct CalendarCanvasView: View {
    @Binding var selectedDate: Date
    let items: [CalendarTimelineItem]
    let projects: [Project]
    let isDrawingMode: Bool
    let onSelectDay: (Date) -> Void
    let onSelectEvent: (CalendarTimelineItem) -> Void

    @State private var zoomScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var drawingData: Data = Data()

    private var drawingKey: String {
        "nouae.calendar.drawing.\(selectedDate.formatted(.dateTime.year().month(.twoDigits)))"
    }

    var body: some View {
        AppPanel(title: "Canvas", subtitle: "Pan, zoom, and annotate the month flow") {
            ZStack {
                CalendarCanvasGrid(
                    selectedDate: selectedDate,
                    items: items,
                    zoomScale: zoomScale,
                    onSelectDay: onSelectDay,
                    onSelectEvent: onSelectEvent
                )
                .scaleEffect(zoomScale)
                .offset(panOffset)
                .animation(.easeInOut(duration: 0.18), value: zoomScale)
                .animation(.easeInOut(duration: 0.18), value: panOffset)
                .gesture(canvasGesture)
                .allowsHitTesting(!isDrawingMode)

                if isDrawingMode {
                    CalendarDrawingOverlay(data: $drawingData)
                        .clipShape(RoundedRectangle(cornerRadius: AppUI.Radius.card, style: .continuous))
                        .transition(.opacity)
                }
            }
            .frame(minHeight: 560)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: AppUI.Radius.card, style: .continuous))
            .overlay(alignment: .topTrailing) {
                StatusBadge(zoomLabel, tone: .blue, symbolName: isDrawingMode ? "pencil.tip" : "hand.draw")
                    .padding(12)
            }
            .onAppear { loadDrawing() }
            .onChange(of: selectedDate) { _, _ in loadDrawing() }
            .onChange(of: drawingData) { _, _ in saveDrawing() }
        }
    }

    private var canvasGesture: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in zoomScale = min(max(value, 0.62), 1.4) },
            DragGesture()
                .onChanged { value in panOffset = value.translation }
        )
    }

    private var zoomLabel: String {
        if isDrawingMode { return "Drawing Mode" }
        if zoomScale >= 1.15 { return "High Zoom" }
        if zoomScale >= 0.85 { return "Medium Zoom" }
        return "Low Zoom"
    }

    private func loadDrawing() {
        drawingData = UserDefaults.standard.data(forKey: drawingKey) ?? Data()
    }

    private func saveDrawing() {
        UserDefaults.standard.set(drawingData, forKey: drawingKey)
    }
}
