import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: DrawingViewModel
    let onImportRequested: () -> Void
    var onClose: (() -> Void)?
    var panelTint: Color = Color(nsColor: NSColor(calibratedWhite: 0.23, alpha: 0.9))
    @StateObject private var visionTracer = VisionTracer()
    @State private var showingExportDialog = false
    @State private var showingTraceSettings = false
    @State private var showingTraceProgress = false
    @State private var traceThreshold: Double = 0.5
    @State private var exportExtrusion: Double = 50.0
    @State private var useVisionTracing = true

    private let toolColumns = [
        GridItem(.flexible(minimum: 50), spacing: 10),
        GridItem(.flexible(minimum: 50), spacing: 10),
        GridItem(.flexible(minimum: 50), spacing: 10)
    ]

    var body: some View {
        GlassPanel(cornerRadius: 12, tint: panelTint, opacity: 0.85) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Tools")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Button {
                        onClose?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Drawing Modes")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: toolColumns, spacing: 10) {
                        ForEach(DrawingTool.allCases, id: \.self) { tool in
                            ToolButton(
                                icon: tool.icon,
                                isSelected: viewModel.currentTool == tool,
                                action: {
                                    viewModel.currentTool = tool
                                }
                            )
                            .frame(height: 36)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        ColorPicker("", selection: $viewModel.currentColor)
                            .labelsHidden()
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading) {
                            Text("Wall Thickness")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $viewModel.wallThickness, in: 1...40)
                        }
                        Text("\(Int(viewModel.wallThickness)) cm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Reference")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: {
                        onImportRequested()
                    }) {
                        Label("Import Reference", systemImage: "photo")
                    }

                    if viewModel.referenceImage != nil {
                        HStack {
                            Text("Opacity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $viewModel.referenceImageOpacity, in: 0...1)
                        }

                        HStack {
                            Button(action: {
                                performTrace()
                            }) {
                                Label("Trace", systemImage: "wand.and.stars")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.referenceImage == nil)

                            Button(action: {
                                showingTraceSettings = true
                            }) {
                                Label("Settings", systemImage: "slider.horizontal.2.square")
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Editing")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Button(action: {
                            viewModel.undo()
                        }) {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                        }

                        Button(action: {
                            viewModel.clearCanvas()
                        }) {
                            Label("Clear", systemImage: "trash")
                        }
                    }
                }

                Spacer(minLength: 0)

                Button(action: {
                    exportExtrusion = viewModel.totalExtrusionHeight
                    showingExportDialog = true
                }) {
                    HStack {
                        Image(systemName: "cube.transparent")
                        Text("Export 3D")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.paths.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 320)
        .sheet(isPresented: $showingTraceSettings) {
            TraceSettingsView(
                threshold: $traceThreshold,
                useVisionTracing: $useVisionTracing,
                onTrace: {
                    performTrace()
                },
                onCancel: {
                    showingTraceSettings = false
                }
            )
        }
        .sheet(isPresented: $showingTraceProgress) {
            VStack(spacing: 20) {
                Text("Processing Image...")
                    .font(.title2)
                    .fontWeight(.semibold)

                ProgressView(value: visionTracer.progress)
                    .frame(width: 300)

                Text("\(Int(visionTracer.progress * 100))%")
                    .foregroundColor(.secondary)
            }
            .padding(40)
            .frame(width: 400, height: 200)
        }
        .sheet(isPresented: $showingExportDialog) {
            ExportSettingsView(
                extrusion: $exportExtrusion,
                onExport: { fileURL in
                    exportTo3D(fileURL: fileURL, extrusion: exportExtrusion)
                },
                onCancel: {
                    showingExportDialog = false
                }
            )
        }
    }

    private func performTrace() {
        guard let image = viewModel.referenceImage else { return }

        showingTraceSettings = false
        showingTraceProgress = true

        if useVisionTracing {
            visionTracer.traceImage(image) { tracedPaths in
                viewModel.paths.append(contentsOf: tracedPaths)
                showingTraceProgress = false
            }
        } else {
            let tracedPaths = ImageTracer.traceImage(image, threshold: traceThreshold, simplification: 2.0)
            viewModel.paths.append(contentsOf: tracedPaths)
            showingTraceProgress = false
        }
    }

    private func exportTo3D(fileURL: URL, extrusion: Double) {
        let success = Model3DGenerator.exportToRhino(
            paths: viewModel.paths,
            extrusion: extrusion,
            fileURL: fileURL
        )

        if success {
            print("Successfully exported to: \(fileURL.path)")
        } else {
            print("Export failed")
        }

        showingExportDialog = false
    }
}

struct ToolButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.borderless)
    }
}
