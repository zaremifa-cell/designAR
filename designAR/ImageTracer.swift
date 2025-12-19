import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageTracer {
    static func traceImage(_ image: NSImage, threshold: Double = 0.5, simplification: Double = 2.0) -> [DrawingPath] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return []
        }

        let ciImage = CIImage(cgImage: cgImage)
        var paths: [DrawingPath] = []

        let edgeDetector = detectEdges(ciImage: ciImage, threshold: threshold)

        if let processedImage = edgeDetector {
            let contours = extractContours(from: processedImage, simplification: simplification)
            paths = contours
        }

        return paths
    }

    private static func detectEdges(ciImage: CIImage, threshold: Double) -> CIImage? {
        let grayscaleFilter = CIFilter.colorControls()
        grayscaleFilter.inputImage = ciImage
        grayscaleFilter.saturation = 0.0

        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = grayscaleFilter.outputImage
        edgeFilter.intensity = Float(threshold * 10)

        return edgeFilter.outputImage
    }

    private static func extractContours(from ciImage: CIImage, simplification: Double) -> [DrawingPath] {
        let context = CIContext()
        var paths: [DrawingPath] = []

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return paths
        }

        let width = cgImage.width
        let height = cgImage.height

        guard let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return paths
        }

        var visited = Array(repeating: Array(repeating: false, count: width), count: height)
        let bytesPerPixel = 4

        for y in stride(from: 0, to: height, by: Int(simplification)) {
            for x in stride(from: 0, to: width, by: Int(simplification)) {
                if visited[y][x] { continue }

                let pixelIndex = (y * width + x) * bytesPerPixel
                let intensity = data[pixelIndex]

                if intensity > 128 {
                    let contour = traceContour(
                        data: data,
                        width: width,
                        height: height,
                        startX: x,
                        startY: y,
                        visited: &visited,
                        bytesPerPixel: bytesPerPixel
                    )

                    if contour.count > 3 {
                        let path = DrawingPath(
                            points: contour,
                            color: .black,
                            lineWidth: 2.0,
                            tool: .pencil
                        )
                        paths.append(path)
                    }
                }
            }
        }

        return paths
    }

    private static func traceContour(
        data: UnsafePointer<UInt8>,
        width: Int,
        height: Int,
        startX: Int,
        startY: Int,
        visited: inout [[Bool]],
        bytesPerPixel: Int
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        var queue: [(Int, Int)] = [(startX, startY)]

        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)]
        var pointSet: Set<String> = []

        while !queue.isEmpty && points.count < 1000 {
            let (x, y) = queue.removeFirst()

            if x < 0 || x >= width || y < 0 || y >= height { continue }
            if visited[y][x] { continue }

            let pixelIndex = (y * width + x) * bytesPerPixel
            let intensity = data[pixelIndex]

            if intensity > 128 {
                visited[y][x] = true
                let pointKey = "\(x),\(y)"

                if !pointSet.contains(pointKey) {
                    points.append(CGPoint(x: x, y: y))
                    pointSet.insert(pointKey)
                }

                for (dx, dy) in directions {
                    let newX = x + dx
                    let newY = y + dy
                    if newX >= 0 && newX < width && newY >= 0 && newY < height && !visited[newY][newX] {
                        queue.append((newX, newY))
                    }
                }
            }
        }

        return simplifyPath(points: points, tolerance: 2.0)
    }

    private static func simplifyPath(points: [CGPoint], tolerance: Double) -> [CGPoint] {
        if points.count < 3 { return points }

        var simplified: [CGPoint] = [points[0]]
        var lastPoint = points[0]

        for i in 1..<points.count {
            let currentPoint = points[i]
            let distance = sqrt(
                pow(currentPoint.x - lastPoint.x, 2) +
                pow(currentPoint.y - lastPoint.y, 2)
            )

            if distance > tolerance {
                simplified.append(currentPoint)
                lastPoint = currentPoint
            }
        }

        if let last = points.last, last != lastPoint {
            simplified.append(last)
        }

        return simplified
    }
}
