import PencilKit
import SwiftUI

struct CalendarDrawingOverlay: UIViewRepresentable {
    @Binding var data: Data

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        canvas.delegate = context.coordinator
        if let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        guard let drawing = try? PKDrawing(data: data), uiView.drawing.dataRepresentation() != data else { return }
        uiView.drawing = drawing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(data: $data)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var data: Data

        init(data: Binding<Data>) {
            _data = data
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            data = canvasView.drawing.dataRepresentation()
        }
    }
}
