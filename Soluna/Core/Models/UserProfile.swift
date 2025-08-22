import Foundation

struct UserProfile: Identifiable, Codable {
    var id: String   // = uid
    var displayName: String?
    var photoURL: String?
    var createdAt: Date
}
