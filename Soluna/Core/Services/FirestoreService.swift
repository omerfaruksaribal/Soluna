import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    private var db: Firestore { Firestore.firestore() }

    func moodsRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("moods")
    }
    func habitsRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("habits")
    }
    func habitLogsRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("habitLogs")
    }
}
