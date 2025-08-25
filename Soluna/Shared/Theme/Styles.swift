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

    static func cardRowBackground() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(BrandColor.card)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.vertical, 6)
    }
}
