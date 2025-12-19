import Foundation
import SceneKit
import SwiftUI

struct Point3D {
    var x: Double
    var y: Double
    var z: Double
}

struct Face3D {
    var vertices: [Point3D]
}

class Model3DGenerator {

    static func generate3DModel(from paths: [DrawingPath], extrusion: Double = 50.0) -> SCNNode {
        let rootNode = SCNNode()

        for path in paths {
            if path.points.count < 2 { continue }

            let extrudedNode = createExtrudedGeometry(from: path.points, depth: CGFloat(extrusion))
            rootNode.addChildNode(extrudedNode)
        }

        return rootNode
    }

    private static func createExtrudedGeometry(from points: [CGPoint], depth: CGFloat) -> SCNNode {
        let bezierPath = NSBezierPath()

        if let firstPoint = points.first {
            bezierPath.move(to: firstPoint)
            for point in points.dropFirst() {
                bezierPath.line(to: point)
            }
        }

        let shape = SCNShape(path: bezierPath, extrusionDepth: depth)

        let material = SCNMaterial()
        material.diffuse.contents = NSColor.lightGray
        material.specular.contents = NSColor.white
        material.isDoubleSided = true
        shape.materials = [material]

        let node = SCNNode(geometry: shape)
        node.position = SCNVector3(x: 0, y: 0, z: 0)

        return node
    }

    static func exportToRhino(paths: [DrawingPath], extrusion: Double, fileURL: URL) -> Bool {
        var objContent = "# designAR Export\n"
        objContent += "# Compatible with Rhino 3D and Grasshopper\n\n"

        var vertexIndex = 1

        for (pathIndex, path) in paths.enumerated() {
            objContent += "# Path \(pathIndex + 1)\n"

            let points3D = convert2DTo3D(points: path.points, extrusion: extrusion)

            for point in points3D {
                objContent += "v \(point.x) \(point.y) \(point.z)\n"
            }

            for point in points3D {
                let extrudedPoint = Point3D(x: point.x, y: point.y, z: point.z + extrusion)
                objContent += "v \(extrudedPoint.x) \(extrudedPoint.y) \(extrudedPoint.z)\n"
            }

            let baseCount = points3D.count

            for i in 0..<baseCount {
                let current = vertexIndex + i
                let next = vertexIndex + ((i + 1) % baseCount)
                let currentTop = current + baseCount
                let nextTop = next + baseCount

                objContent += "f \(current) \(next) \(nextTop) \(currentTop)\n"
            }

            var baseIndices = ""
            for i in 0..<baseCount {
                baseIndices += "\(vertexIndex + i) "
            }
            objContent += "f \(baseIndices)\n"

            var topIndices = ""
            for i in (0..<baseCount).reversed() {
                topIndices += "\(vertexIndex + baseCount + i) "
            }
            objContent += "f \(topIndices)\n"

            vertexIndex += baseCount * 2
            objContent += "\n"
        }

        do {
            try objContent.write(to: fileURL, atomically: true, encoding: .utf8)

            let readmeURL = fileURL.deletingLastPathComponent().appendingPathComponent("README.txt")
            let readme = """
            designAR 3D Export

            This file contains a 3D model exported from designAR.

            Import Instructions:
            1. Open Rhino 3D
            2. File > Import > Select the .obj file
            3. The model will be imported as a mesh
            4. Use 'MeshToNURB' command to convert to NURBS surfaces if needed

            For Grasshopper:
            1. Use the 'File Path' component to reference this .obj file
            2. Use 'Import 3DM' or mesh import components
            3. Process as needed in your Grasshopper definition

            Technical Details:
            - Format: Wavefront OBJ
            - Units: Millimeters (adjust scale in Rhino as needed)
            - Coordinate System: Right-handed
            """
            try readme.write(to: readmeURL, atomically: true, encoding: .utf8)

            return true
        } catch {
            print("Error exporting to file: \(error)")
            return false
        }
    }

    private static func convert2DTo3D(points: [CGPoint], extrusion: Double) -> [Point3D] {
        return points.map { point in
            Point3D(x: Double(point.x), y: Double(point.y), z: 0.0)
        }
    }

    static func generateGrasshopperData(from paths: [DrawingPath]) -> String {
        var ghData = "{\n"
        ghData += "  \"version\": \"1.0\",\n"
        ghData += "  \"type\": \"designAR_Export\",\n"
        ghData += "  \"paths\": [\n"

        for (index, path) in paths.enumerated() {
            ghData += "    {\n"
            ghData += "      \"id\": \(index),\n"
            ghData += "      \"points\": [\n"

            for (pointIndex, point) in path.points.enumerated() {
                ghData += "        {\"x\": \(point.x), \"y\": \(point.y), \"z\": 0.0}"
                if pointIndex < path.points.count - 1 {
                    ghData += ","
                }
                ghData += "\n"
            }

            ghData += "      ],\n"
            ghData += "      \"closed\": false\n"
            ghData += "    }"

            if index < paths.count - 1 {
                ghData += ","
            }
            ghData += "\n"
        }

        ghData += "  ]\n"
        ghData += "}\n"

        return ghData
    }
}

#if os(macOS)
import Cocoa

extension Model3DGenerator {
    static func show3DPreview(paths: [DrawingPath], extrusion: Double = 50.0) {
        let scene = SCNScene()

        let model = generate3DModel(from: paths, extrusion: extrusion)
        scene.rootNode.addChildNode(model)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 300)
        scene.rootNode.addChildNode(cameraNode)

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 50, z: 50)
        scene.rootNode.addChildNode(lightNode)

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
    }
}
#endif
