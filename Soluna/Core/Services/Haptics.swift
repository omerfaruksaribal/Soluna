import SwiftUI

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func impact()  {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
