import SwiftUI

struct CanvasView: View {
    @ObservedObject var viewModel: DrawingViewModel
    var onImportRequested: (() -> Void)?
    @State private var currentDragPoint: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear

                if let refImage = viewModel.referenceImage {
                    Image(nsImage: refImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(viewModel.referenceImageOpacity)
                }

                Canvas { context, size in
                    for path in viewModel.paths {
                        var cgPath = Path()
                        if let firstPoint = path.points.first {
                            cgPath.move(to: firstPoint)
                            for point in path.points.dropFirst() {
                                cgPath.addLine(to: point)
                            }
                        }

                        context.stroke(
                            cgPath,
                            with: .color(path.color),
                            lineWidth: path.lineWidth
                        )
                    }

                    if let currentPath = viewModel.currentPath {
                        var cgPath = Path()
                        if let firstPoint = currentPath.points.first {
                            cgPath.move(to: firstPoint)
                            for point in currentPath.points.dropFirst() {
                                cgPath.addLine(to: point)
                            }
                        }

                        context.stroke(
                            cgPath,
                            with: .color(currentPath.color),
                            lineWidth: currentPath.lineWidth
                        )
                    }
                }

                if let importAction = onImportRequested,
                   viewModel.referenceImage == nil,
                   viewModel.paths.isEmpty {
                    Button(action: importAction) {
                        ZStack {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 120, height: 6)
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 120)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if viewModel.currentPath == nil {
                            viewModel.startDrawing(at: value.location)
                        } else {
                            viewModel.continueDrawing(at: value.location)
                        }
                        currentDragPoint = value.location
                    }
                    .onEnded { _ in
                        viewModel.endDrawing()
                        currentDragPoint = nil
                    }
            )
        }
    }
}
