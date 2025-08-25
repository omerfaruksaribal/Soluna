import FirebaseFirestore

final class MoodRepository {
    private let db = Firestore.firestore()
    private func moodsRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("moods")
    }

    func fetchRecent(uid: String, limit: Int = 60) async throws -> [MoodEntry] {
        let snap = try await moodsRef(uid: uid)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snap.documents.map { doc in
            let d = doc.data()
            return MoodEntry(
                id: doc.documentID,
                mood: d["mood"] as? String ?? "neutral",
                note: (d["note"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                date: (d["date"] as? Timestamp)?.dateValue() ?? .now
            )
        }
    }

    func add(uid: String, mood: String, note: String?) async throws -> MoodEntry {
        let now = Date()
        let payload: [String: Any] = [
            "mood": mood,
            "note": note ?? "",
            "date": Timestamp(date: now)
        ]
        let ref = try await moodsRef(uid: uid).addDocument(data: payload)
        return MoodEntry(id: ref.documentID, mood: mood, note: note, date: now)
    }

    func delete(uid: String, moodId: String) async throws {
        try await moodsRef(uid: uid).document(moodId).delete()
    }
}
