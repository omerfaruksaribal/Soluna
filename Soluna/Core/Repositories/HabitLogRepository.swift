import FirebaseFirestore

enum HabitError: LocalizedError, Equatable {
    case targetReached
    var errorDescription: String? { "Daily target reached." }
}

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

    func todayCounts(uid: String, today: Date = .now) async throws -> [String:Int] {
        let day = Self.startOfDay(today)
        let snap = try await logsRef(uid: uid)
            .whereField("date", isEqualTo: Timestamp(date: day))
            .getDocuments()

        var out: [String:Int] = [:]
        for doc in snap.documents {
            let d = doc.data()
            let id = d["habitId"] as? String ?? ""
            let c  = d["count"] as? Int ?? 0
            out[id] = c
        }
        return out
    }

    /// Tick: makes the that day's documnet upsert, count increases by 1.
    func tickCapped(uid: String, habit: Habit, on date: Date = .now) async throws -> Int {
        guard let habitId = habit.id else { return 0 }

        let key   = Self.dayKey(date)
        let docId = "\(habitId)_\(key)"
        let ref   = logsRef(uid: uid).document(docId)
        let sod   = Self.startOfDay(date)

        // mevcut sayıyı oku
        let currentSnap = try await ref.getDocument()
        let current = (currentSnap.data()?["count"] as? Int) ?? 0

        // hedefe ulaştıysa dur
        if current >= habit.targetPerDay {
            throw HabitError.targetReached
        }

        // +1 yaz (sunucu tarafında güvenli artırım)
        try await ref.setData([
            "habitId": habitId,
            "date": Timestamp(date: sod),
            "count": FieldValue.increment(Int64(1))
        ], merge: true)

        return current + 1
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
}

extension HabitLogRepository {
    /// simple streak calc
    func streak(uid: String, habitId: String, lookbackDays: Int = 90) async throws -> Int {
        let now  = Self.startOfDay(.now)
        let from = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: now)!

        let snap = try await logsRef(uid: uid)
            .whereField("habitId", isEqualTo: habitId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: from))
            .whereField("date", isLessThan: Timestamp(date: now.addingTimeInterval(24*3600)))
            .order(by: "date", descending: true)
            .getDocuments()

        var days: Set<String> = []
        for d in snap.documents {
            if let ts = d.data()["date"] as? Timestamp {
                days.insert(Self.dayKey(ts.dateValue()))
            }
        }

        var streak = 0
        var cursor = now
        while days.contains(Self.dayKey(cursor)) {
            streak += 1
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }
}
