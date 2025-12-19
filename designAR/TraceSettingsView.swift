import SwiftUI

struct TraceSettingsView: View {
    @Binding var threshold: Double
    @Binding var useVisionTracing: Bool
    let onTrace: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Auto-Trace Settings")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detection Method")
                        .font(.headline)

                    Picker("", selection: $useVisionTracing) {
                        Text("AI Vision (Recommended)").tag(true)
                        Text("Classic Edge Detection").tag(false)
                    }
                    .pickerStyle(.radioGroup)

                    if useVisionTracing {
                        Text("Uses Apple Vision Framework for intelligent line and shape detection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Simple CoreImage edge detection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Edge Detection Threshold")
                        .font(.headline)

                    HStack {
                        Slider(value: $threshold, in: 0.1...1.0)
                        Text(String(format: "%.2f", threshold))
                            .frame(width: 45)
                            .foregroundColor(.secondary)
                    }

                    Text("Higher values detect stronger edges only")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Trace Image") {
                    onTrace()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
