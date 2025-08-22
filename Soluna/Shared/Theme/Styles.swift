import SwiftUI

enum Styles {
    // “Glass-like card”: Card color + thin stroke
    static func cardContainer() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(BrandColor.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}
