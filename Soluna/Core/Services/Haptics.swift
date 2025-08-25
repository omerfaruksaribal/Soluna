import SwiftUI

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }

    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }

    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }

    static func impact()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
}
