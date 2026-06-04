import SwiftUI

#if canImport(PencilKit) && canImport(UIKit)
import PencilKit

struct CalendarDrawingOverlay: UIViewRepresentable {
    @Binding var data: Data

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        canvas.delegate = context.coordinator

        if !data.isEmpty, let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        guard !data.isEmpty else {
            uiView.drawing = PKDrawing()
            return
        }

        guard uiView.drawing.dataRepresentation() != data,
              let drawing = try? PKDrawing(data: data) else { return }
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
#else
struct CalendarDrawingOverlay: View {
    @Binding var data: Data

    var body: some View {
        ZStack {
            Color.clear
            VStack(spacing: 8) {
                Image(systemName: "pencil.tip")
                    .font(.title2)
                Text("Drawing Mode")
                    .font(.headline)
                Text("Apple Pencil drawing is unavailable in this runtime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
#endif
