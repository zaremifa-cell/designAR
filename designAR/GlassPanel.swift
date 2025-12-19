import SwiftUI

struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = 12
    var tint: Color
    var opacity: Double = 0.92
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tint.opacity(opacity))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.6)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 4)

            content()
                .padding()
        }
    }
}
