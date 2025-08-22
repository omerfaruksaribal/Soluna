import Foundation
import FirebaseFirestore

struct MoodEntry: Identifiable, Codable {
    var id: String?
    var mood: String
    var note: String?
    var date: Date
}
