import SwiftUI
import SceneKit
import AppKit

struct ModelPreviewView: View {
    @ObservedObject var viewModel: DrawingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("3D Preview")
                .font(.headline)

            SceneView(
                scene: makeScene(),
                options: [.allowsCameraControl, .autoenablesDefaultLighting]
            )
            .frame(minHeight: 300)
            .background(Color.black.opacity(0.05))
            .overlay(alignment: .center) {
                if viewModel.paths.isEmpty {
                    Text("Trace a reference to preview the 3D volume.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()

        let model = Model3DGenerator.generate3DModel(
            from: viewModel.paths,
            extrusion: viewModel.totalExtrusionHeight
        )
        scene.rootNode.addChildNode(model)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(
            x: 0,
            y: 0,
            z: CGFloat(max(viewModel.totalExtrusionHeight * 4, 600))
        )
        cameraNode.eulerAngles = SCNVector3(
            x: CGFloat(-0.3),
            y: CGFloat(0.4),
            z: 0
        )
        scene.rootNode.addChildNode(cameraNode)

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 200, y: 200, z: 200)
        scene.rootNode.addChildNode(lightNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = NSColor(white: 0.5, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)

        return scene
    }
}
