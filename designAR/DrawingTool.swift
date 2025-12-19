import SwiftUI

enum DrawingTool: String, CaseIterable {
    case select = "Selection"
    case pencil = "Pencil"
    case brush = "Brush"
    case eraser = "Eraser"
    case line = "Line"
    case rectangle = "Rectangle"
    case ellipse = "Ellipse"
    case measure = "Measure"

    var icon: String {
        switch self {
        case .select: return "cursorarrow"
        case .pencil: return "pencil"
        case .brush: return "paintbrush"
        case .eraser: return "eraser"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .measure: return "ruler"
        }
    }
}

struct DrawingPath: Identifiable, Equatable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var tool: DrawingTool

    static func == (lhs: DrawingPath, rhs: DrawingPath) -> Bool {
        lhs.id == rhs.id
    }
}

class DrawingViewModel: ObservableObject {
    @Published var paths: [DrawingPath] = []
    @Published var currentTool: DrawingTool = .pencil
    @Published var currentColor: Color = .black
    @Published var lineWidth: CGFloat = 2.0
    @Published var referenceImage: NSImage?
    @Published var referenceImageOpacity: Double = 0.5
    @Published var wallThickness: Double = 6.0 {
        didSet {
            lineWidth = CGFloat(wallThickness)
        }
    }
    @Published var wallHeight: Double = 120.0
    @Published var floorCount: Int = 1

    var currentPath: DrawingPath?
    var totalExtrusionHeight: Double {
        wallHeight * Double(max(floorCount, 1))
    }

    init() {
        lineWidth = CGFloat(wallThickness)
    }

    func startDrawing(at point: CGPoint) {
        currentPath = DrawingPath(
            points: [point],
            color: currentColor,
            lineWidth: lineWidth,
            tool: currentTool
        )
    }

    func continueDrawing(at point: CGPoint) {
        currentPath?.points.append(point)
    }

    func endDrawing() {
        if let path = currentPath {
            paths.append(path)
            currentPath = nil
        }
    }

    func clearCanvas() {
        paths.removeAll()
    }

    func undo() {
        if !paths.isEmpty {
            paths.removeLast()
        }
    }

    func loadReferenceImage(from url: URL) {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if let image = NSImage(contentsOf: url) {
            DispatchQueue.main.async {
                self.referenceImage = image
            }
        }
    }
}
