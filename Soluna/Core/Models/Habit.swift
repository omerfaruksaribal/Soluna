import Foundation
import FirebaseFirestore

struct Habit: Identifiable, Codable {
    var id: String?
    var title: String
    var targetPerDay: Int
    var isActive: Bool
    var createdAt: Date
}
