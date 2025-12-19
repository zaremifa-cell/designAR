import Foundation
import Vision
import CoreImage
import AppKit

struct DetectedLine {
    var start: CGPoint
    var end: CGPoint
    var confidence: Float
    var angle: CGFloat

    var length: CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        return sqrt(dx * dx + dy * dy)
    }
}

struct ArchitecturalFeature {
    var lines: [DetectedLine]
    var corners: [CGPoint]
    var vanishingPoints: [CGPoint]
    var type: FeatureType

    enum FeatureType {
        case wall
        case window
        case door
        case roof
        case floor
        case unknown
    }
}

class VisionTracer: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var detectedLines: [DetectedLine] = []
    @Published var detectedCorners: [CGPoint] = []

    func traceImage(_ image: NSImage, completion: @escaping ([DrawingPath]) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion([])
            return
        }

        isProcessing = true
        progress = 0.0

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var allPaths: [DrawingPath] = []

            self.updateProgress(0.2)
            let contours = self.detectContours(cgImage: cgImage)

            self.updateProgress(0.4)
            let lines = self.detectLines(cgImage: cgImage)

            self.updateProgress(0.6)
            let rectangles = self.detectRectangles(cgImage: cgImage)

            self.updateProgress(0.8)
            let optimizedLines = self.optimizeLines(lines)

            allPaths.append(contentsOf: contours)
            allPaths.append(contentsOf: optimizedLines)
            allPaths.append(contentsOf: rectangles)

            self.updateProgress(1.0)

            DispatchQueue.main.async {
                self.isProcessing = false
                completion(allPaths)
            }
        }
    }

    private func updateProgress(_ value: Double) {
        DispatchQueue.main.async {
            self.progress = value
        }
    }

    private func detectContours(cgImage: CGImage) -> [DrawingPath] {
        var paths: [DrawingPath] = []

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.5
        request.detectsDarkOnLight = true

        do {
            try requestHandler.perform([request])

            guard let results = request.results else { return paths }

            for observation in results {
                let contourCount = observation.contourCount

                for i in 0..<contourCount {
                    if let contour = try? observation.contour(at: i) {
                        let points = convertVNContoursToPoints(contour, imageSize: CGSize(width: cgImage.width, height: cgImage.height))

                        if points.count > 2 {
                            let path = DrawingPath(
                                points: points,
                                color: .black,
                                lineWidth: 2.0,
                                tool: .pencil
                            )
                            paths.append(path)
                        }
                    }
                }
            }
        } catch {
            print("Contour detection error: \(error)")
        }

        return paths
    }

    private func detectLines(cgImage: CGImage) -> [DetectedLine] {
        var detectedLines: [DetectedLine] = []

        let ciImage = CIImage(cgImage: cgImage)

        guard let edgeFilter = CIFilter(name: "CIEdges") else { return detectedLines }
        edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let outputImage = edgeFilter.outputImage else { return detectedLines }

        let context = CIContext()
        guard let processedCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return detectedLines
        }

        let width = processedCGImage.width
        let height = processedCGImage.height

        guard let dataProvider = processedCGImage.dataProvider,
              let pixelData = dataProvider.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return detectedLines
        }

        let bytesPerPixel = 4
        let threshold: UInt8 = 100

        var edgePoints: [CGPoint] = []
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let pixelIndex = (y * width + x) * bytesPerPixel
                let intensity = data[pixelIndex]

                if intensity > threshold {
                    edgePoints.append(CGPoint(x: x, y: y))
                }
            }
        }

        let lines = houghLineTransform(points: edgePoints, width: width, height: height)
        detectedLines.append(contentsOf: lines)

        DispatchQueue.main.async {
            self.detectedLines = detectedLines
        }

        return detectedLines
    }

    private func houghLineTransform(points: [CGPoint], width: Int, height: Int) -> [DetectedLine] {
        var lines: [DetectedLine] = []

        let angleStep = Double.pi / 180.0
        let distanceResolution = 1.0

        var accumulator: [Int: [Int: Int]] = [:]

        for point in points {
            for angle in stride(from: 0.0, to: Double.pi, by: angleStep) {
                let distance = Double(point.x) * cos(angle) + Double(point.y) * sin(angle)
                let distanceBucket = Int(distance / distanceResolution)
                let angleBucket = Int(angle / angleStep)

                accumulator[angleBucket, default: [:]][distanceBucket, default: 0] += 1
            }
        }

        let threshold = 20

        for (angleBucket, distances) in accumulator {
            for (distanceBucket, votes) in distances {
                if votes > threshold {
                    let angle = Double(angleBucket) * angleStep
                    let distance = Double(distanceBucket) * distanceResolution

                    let x1: CGFloat
                    let y1: CGFloat
                    let x2: CGFloat
                    let y2: CGFloat

                    if abs(sin(angle)) > 0.001 {
                        x1 = 0
                        y1 = CGFloat((distance - Double(x1) * cos(angle)) / sin(angle))
                        x2 = CGFloat(width)
                        y2 = CGFloat((distance - Double(x2) * cos(angle)) / sin(angle))
                    } else {
                        y1 = 0
                        x1 = CGFloat(distance / cos(angle))
                        y2 = CGFloat(height)
                        x2 = CGFloat(distance / cos(angle))
                    }

                    let line = DetectedLine(
                        start: CGPoint(x: x1, y: y1),
                        end: CGPoint(x: x2, y: y2),
                        confidence: Float(votes) / Float(threshold),
                        angle: CGFloat(angle)
                    )
                    lines.append(line)
                }
            }
        }

        return lines
    }

    private func detectRectangles(cgImage: CGImage) -> [DrawingPath] {
        var paths: [DrawingPath] = []

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.1
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.05
        request.maximumObservations = 20

        do {
            try requestHandler.perform([request])

            guard let results = request.results else { return paths }

            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

            for observation in results {
                let points = [
                    convertNormalizedPoint(observation.topLeft, imageSize: imageSize),
                    convertNormalizedPoint(observation.topRight, imageSize: imageSize),
                    convertNormalizedPoint(observation.bottomRight, imageSize: imageSize),
                    convertNormalizedPoint(observation.bottomLeft, imageSize: imageSize),
                    convertNormalizedPoint(observation.topLeft, imageSize: imageSize)
                ]

                let path = DrawingPath(
                    points: points,
                    color: .blue,
                    lineWidth: 2.0,
                    tool: .rectangle
                )
                paths.append(path)
            }
        } catch {
            print("Rectangle detection error: \(error)")
        }

        return paths
    }

    private func optimizeLines(_ lines: [DetectedLine]) -> [DrawingPath] {
        var paths: [DrawingPath] = []

        let mergedLines = mergeNearbyLines(lines)

        for line in mergedLines {
            if line.length > 10 && line.confidence > 0.5 {
                let path = DrawingPath(
                    points: [line.start, line.end],
                    color: .red,
                    lineWidth: 1.5,
                    tool: .line
                )
                paths.append(path)
            }
        }

        return paths
    }

    private func mergeNearbyLines(_ lines: [DetectedLine]) -> [DetectedLine] {
        var merged: [DetectedLine] = []
        var used = Set<Int>()

        for i in 0..<lines.count {
            if used.contains(i) { continue }

            var currentLine = lines[i]
            used.insert(i)

            for j in (i + 1)..<lines.count {
                if used.contains(j) { continue }

                let otherLine = lines[j]

                let angleDiff = abs(currentLine.angle - otherLine.angle)
                if angleDiff < 0.1 || angleDiff > (Double.pi - 0.1) {
                    let distance = distanceBetweenLines(currentLine, otherLine)

                    if distance < 20 {
                        currentLine = mergeTwoLines(currentLine, otherLine)
                        used.insert(j)
                    }
                }
            }

            merged.append(currentLine)
        }

        return merged
    }

    private func distanceBetweenLines(_ line1: DetectedLine, _ line2: DetectedLine) -> CGFloat {
        let d1 = distance(from: line1.start, to: line2.start)
        let d2 = distance(from: line1.start, to: line2.end)
        let d3 = distance(from: line1.end, to: line2.start)
        let d4 = distance(from: line1.end, to: line2.end)

        return min(d1, d2, d3, d4)
    }

    private func mergeTwoLines(_ line1: DetectedLine, _ line2: DetectedLine) -> DetectedLine {
        let allPoints = [line1.start, line1.end, line2.start, line2.end]
        let sortedByX = allPoints.sorted { $0.x < $1.x }

        return DetectedLine(
            start: sortedByX.first!,
            end: sortedByX.last!,
            confidence: (line1.confidence + line2.confidence) / 2,
            angle: (line1.angle + line2.angle) / 2
        )
    }

    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }

    private func convertVNContoursToPoints(_ contour: VNContour, imageSize: CGSize) -> [CGPoint] {
        var points: [CGPoint] = []

        for i in 0..<contour.pointCount {
            let normalizedPoint = contour.normalizedPoints[i]
            let point = CGPoint(
                x: CGFloat(normalizedPoint.x) * imageSize.width,
                y: (1.0 - CGFloat(normalizedPoint.y)) * imageSize.height
            )
            points.append(point)
        }

        return points
    }

    private func convertNormalizedPoint(_ point: CGPoint, imageSize: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x * imageSize.width,
            y: (1.0 - point.y) * imageSize.height
        )
    }
}
