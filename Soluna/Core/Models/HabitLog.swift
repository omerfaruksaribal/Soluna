import Foundation
import FirebaseFirestore

struct HabitLog: Identifiable, Codable {
    var id: String?
    var habitId: String
    var date: Date
    var count: Int
}
