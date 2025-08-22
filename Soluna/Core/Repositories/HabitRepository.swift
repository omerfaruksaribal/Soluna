import FirebaseFirestore

final class HabitRepository {
    private let db = Firestore.firestore()
    private func habitsRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("habits")
    }

    func fetchAll(uid: String) async throws -> [Habit] {
        let snap = try await habitsRef(uid: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snap.documents.map { doc in
            let d = doc.data()
            return Habit(
                id: doc.documentID,
                title: d["title"] as? String ?? "",
                targetPerDay: d["targetPerDay"] as? Int ?? 1,
                isActive: d["isActive"] as? Bool ?? true,
                createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? .now
            )
        }
    }

    func add(uid: String, title: String, targetPerDay: Int) async throws -> Habit {
        let now = Date()
        let payload: [String: Any] = [
            "title": title,
            "targetPerDay": targetPerDay,
            "isActive": true,
            "createdAt": FieldValue.serverTimestamp()   // server-side time
        ]
        let ref = try await habitsRef(uid: uid).addDocument(data: payload)
        return Habit(id: ref.documentID, title: title, targetPerDay: targetPerDay, isActive: true, createdAt: now)
    }

    func setActive(uid: String, habitId: String, isActive: Bool) async throws {
        try await habitsRef(uid: uid).document(habitId).updateData(["isActive": isActive])
    }
}
