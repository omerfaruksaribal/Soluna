import FirebaseFirestore

final class HabitLogRepository {
    private let db = Firestore.firestore()
    private func logsRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("habitLogs")
    }

    // Day keyword: YYYYMMDD
    static func dayKey(_ date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return String(format: "%04d%02d%02d", y, m, d)
    }
    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Tick: makes the that day's documnet upsert, coun increases by 1.
    func tick(uid: String, habitId: String, on date: Date = .now) async throws {
        let key = HabitLogRepository.dayKey(date)
        let docId = "\(habitId)_\(key)"
        let doc = logsRef(uid: uid).document(docId)
        try await doc.setData([
            "habitId": habitId,
            "date": Timestamp(date: HabitLogRepository.startOfDay(date)),
            "count": FieldValue.increment(Int64(1))
        ], merge: true)
    }

    /// brings the daily habit logs  spesific time
    func logs(uid: String, habitId: String, from: Date, to: Date) async throws -> [HabitLog] {
        let snap = try await logsRef(uid: uid)
            .whereField("habitId", isEqualTo: habitId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: HabitLogRepository.startOfDay(from)))
            .whereField("date", isLessThan: Timestamp(date: HabitLogRepository.startOfDay(to)))
            .order(by: "date", descending: true)
            .getDocuments()

        return snap.documents.map { doc in
            let d = doc.data()
            return HabitLog(
                id: doc.documentID,
                habitId: d["habitId"] as? String ?? "",
                date: (d["date"] as? Timestamp)?.dateValue() ?? .now,
                count: d["count"] as? Int ?? 0
            )
        }
    }

    /// simple streak calc
    func streak(uid: String, habitId: String, lookbackDays: Int = 60) async throws -> Int {
        let now = HabitLogRepository.startOfDay(.now)
        let from = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: now)!
        let items = try await logs(uid: uid, habitId: habitId, from: from, to: now.addingTimeInterval(24*3600))

        // logs() already returns daily log
        var set: Set<String> = []
        for l in items {
            set.insert(HabitLogRepository.dayKey(l.date))
        }

        var streak = 0
        var day = now
        while set.contains(HabitLogRepository.dayKey(day)) {
            streak += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }
}
