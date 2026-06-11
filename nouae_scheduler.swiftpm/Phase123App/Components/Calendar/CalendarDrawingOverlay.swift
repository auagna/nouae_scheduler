import PencilKit
import SwiftUI

struct CalendarDrawingOverlay: View {
    @Binding var data: Data

    var body: some View {
        ZStack {
            PencilCanvasRepresentable(data: $data)

            VStack {
                HStack {
                    Spacer()
                    StatusBadge("Pencil Drawing", tone: .blue, symbolName: "pencil.tip")
                        .padding(12)
                }
                Spacer()
            }
        }
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}

private struct PencilCanvasRepresentable: UIViewRepresentable {
    @Binding var data: Data

    func makeCoordinator() -> Coordinator {
        Coordinator(data: $data)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 3)
        context.coordinator.attachToolPicker(to: canvas)
        if let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
            context.coordinator.lastData = data
        }
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        guard data != context.coordinator.lastData,
              let drawing = try? PKDrawing(data: data) else { return }
        canvas.drawing = drawing
        context.coordinator.lastData = data
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var data: Data
        var lastData = Data()
        private let toolPicker = PKToolPicker()

        init(data: Binding<Data>) {
            _data = data
        }

        func attachToolPicker(to canvas: PKCanvasView) {
            toolPicker.addObserver(canvas)
            toolPicker.setVisible(true, forFirstResponder: canvas)
            canvas.becomeFirstResponder()
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let newData = canvasView.drawing.dataRepresentation()
            lastData = newData
            data = newData
        }
    }
}
