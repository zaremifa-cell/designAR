import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DrawingViewModel()
    @State private var isToolbarVisible = false
    @State private var showingImagePicker = false
    @State private var panelOffset: CGSize = .zero
    @State private var panelDragOffset: CGSize = .zero

    private let surfaceColor = Color(nsColor: NSColor(calibratedWhite: 0.28, alpha: 1.0))

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isToolbarVisible.toggle()
                        }
                    }) {
                        Label(isToolbarVisible ? "Hide Tools" : "Show Tools", systemImage: "square.grid.2x2")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(surfaceColor.opacity(0.95))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.05), lineWidth: 0.6)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(surfaceColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.04), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 6)

                    CanvasView(
                        viewModel: viewModel,
                        onImportRequested: { showingImagePicker = true }
                    )
                    .padding(20)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(32)
            .frame(minWidth: 1200, minHeight: 800)
            .background(surfaceColor)
            .edgesIgnoringSafeArea(.all)

            if isToolbarVisible {
                ToolbarView(
                    viewModel: viewModel,
                    onImportRequested: { showingImagePicker = true },
                    onClose: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            isToolbarVisible = false
                            panelOffset = .zero
                            panelDragOffset = .zero
                        }
                    },
                    panelTint: surfaceColor
                )
                .padding(.trailing, 32)
                .padding(.top, 100)
                .offset(x: panelOffset.width + panelDragOffset.width, y: panelOffset.height + panelDragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            panelDragOffset = value.translation
                        }
                        .onEnded { value in
                            panelOffset.width += value.translation.width
                            panelOffset.height += value.translation.height
                            panelDragOffset = .zero
                        }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.loadReferenceImage(from: url)
                }
            case .failure(let error):
                print("Error importing image: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
