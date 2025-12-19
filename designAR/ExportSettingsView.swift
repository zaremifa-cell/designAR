import SwiftUI
import UniformTypeIdentifiers

struct ExportSettingsView: View {
    @Binding var extrusion: Double
    let onExport: (URL) -> Void
    let onCancel: () -> Void

    @State private var showingFileSaver = false

    var body: some View {
        VStack(spacing: 20) {
            Text("3D Export Settings")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Extrusion Depth")
                        .font(.headline)

                    HStack {
                        Slider(value: $extrusion, in: 10...200)
                        Text("\(Int(extrusion)) mm")
                            .frame(width: 60)
                            .foregroundColor(.secondary)
                    }

                    Text("Depth of the 3D extrusion from 2D paths")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Export Format")
                        .font(.headline)

                    HStack {
                        Image(systemName: "cube")
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text("Wavefront OBJ")
                                .fontWeight(.medium)
                            Text("Compatible with Rhino 3D & Grasshopper")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Export") {
                    showingFileSaver = true
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 450)
        .fileExporter(
            isPresented: $showingFileSaver,
            document: TextDocument(text: ""),
            contentType: UTType(filenameExtension: "obj") ?? .plainText,
            defaultFilename: "designAR_export.obj"
        ) { result in
            switch result {
            case .success(let url):
                onExport(url)
            case .failure(let error):
                print("Export error: \(error)")
            }
        }
    }
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
