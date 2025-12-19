import SwiftUI

struct ParameterControlsView: View {
    @ObservedObject var viewModel: DrawingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Parameters")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Floors: \(viewModel.floorCount)")
                    .font(.subheadline)
                Stepper(value: $viewModel.floorCount, in: 1...10) {
                    Text("Adjust floors")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Wall Height: \(Int(viewModel.wallHeight)) cm")
                    .font(.subheadline)
                Slider(value: $viewModel.wallHeight, in: 50...600, step: 10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Wall Thickness: \(Int(viewModel.wallThickness)) cm")
                    .font(.subheadline)
                Slider(value: $viewModel.wallThickness, in: 1...60)
            }

            Text("Total Extrusion: \(Int(viewModel.totalExtrusionHeight)) cm")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
