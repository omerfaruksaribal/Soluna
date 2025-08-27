import Foundation
import FirebaseFirestore

final class RoutineRepository {
    private let db = Firestore.firestore()

    //  MARK: - Paths
    private func routinesRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("routines")
    }

    private func stepsRef(uid: String, routineId: String) -> CollectionReference {
        routinesRef(uid: uid).document(routineId).collection("steps")
    }

    private func routineLogsRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("routineLogs")
    }

    //  MARK: - Create / Update / Delete Routine
    func create(
        uid: String,
        title: String,
        daysOfWeek: [Int] = [1,2,3,4,5,6,7],
        timeOfDay: String = "morning",
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil,
        order: Int = 0
    ) async throws -> String {
        let now = Date()
        let doc = routinesRef(uid: uid).document()
        let data: [String: Any] = [
            "title": title,
            "isActive": true,
            "daysOfWeek": daysOfWeek,
            "timeOfDay": timeOfDay,
            "reminderHour": reminderHour as Any,
            "reminderMinute": reminderMinute as Any,
            "stepsCount": 0,
            "order": order,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]
        try await doc.setData(data)
        return doc.documentID
    }

    func update(uid: String, routineId: String, fields: [String: Any]) async throws {
        var f = fields
        f["updatedAt"] = Timestamp(date: Date())
        try await routinesRef(uid: uid).document(routineId).updateData(f)
    }

    func delete(uid: String, routineId: String) async throws {
        let steps = try await stepsRef(uid: uid, routineId: routineId).getDocuments()
        for s in steps.documents {
            try await s.reference.delete()
        }
        try await routinesRef(uid: uid).document(routineId).delete()
    }

    //  MARK: - Steps
    func addStep(
        uid: String,
        routineId: String,
        title: String,
        habitId: String? = nil,
        order: Int
    ) async throws -> String {
        let doc = stepsRef(uid: uid, routineId: routineId).document()
        let data: [String: Any] = [
            "title": title,
            "habitId": habitId as Any,
            "order": order,
            "isOptional": false
        ]
        try await doc.setData(data)
        // stepsCount++ (atomic)
        try await routinesRef(uid: uid)
            .document(routineId)
            .updateData([
                "stepsCount": FieldValue.increment(Int64(1)),
                "updatedAt": Timestamp(date: Date())
            ])
        return doc.documentID
    }

    //  MARK: - Delete step (and adjust counts)
    func deleteStep(uid: String, routineId: String, stepId: String) async throws {
        // 1) delete step
        try await stepsRef(uid: uid, routineId: routineId).document(stepId).delete()

        // 2) Routine.stepsCount -- (atomic)
        try await routinesRef(uid: uid).document(routineId).updateData([
            "stepsCount": FieldValue.increment(Int64(-1)),
            "updatedAt": Timestamp(date: Date())
        ])

        // 3) fix the todays log (remove the step from completed and update totals)
        let day = DayKey.startOfDay(Date())
        let key = DayKey.key(day)
        let logId = "\(routineId)_\(key)"
        let logRef = routineLogsRef(uid: uid).document(logId)

        _ = try await db.runTransaction { (txn, errorPointer) -> Any? in
            do {
                let doc = try txn.getDocument(logRef)
                guard doc.exists, let data = doc.data() else { return nil }

                var completed = data["completedStepIds"] as? [String] ?? []
                if let idx = completed.firstIndex(of: stepId) {
                    completed.remove(at: idx)
                }

                // read the updated stepsCount from routine to corrected stepsTotal
                let routineRef = self.routinesRef(uid: uid).document(routineId)
                let routineDoc = try txn.getDocument(routineRef)
                let stepsTotal = (routineDoc.data()?["stepsCount"] as? Int) ?? 0
                let isCompleted = stepsTotal > 0 && completed.count >= stepsTotal

                txn.updateData([
                    "completedStepIds": completed,
                    "stepsTotal": stepsTotal,
                    "isCompleted": isCompleted
                ], forDocument: logRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }
    }

    func fetchAll(uid: String) async throws -> [Routine] {
        let snap = try await routinesRef(uid: uid).order(by: "order").getDocuments()
        return snap.documents.compactMap { Self.routineFrom(doc: $0) }
    }

    func fetchSteps(uid: String, routineId: String) async throws -> [RoutineStep] {
        let snap = try await stepsRef(uid: uid, routineId: routineId).order(by: "order").getDocuments()
        return snap.documents.compactMap { Self.stepFrom(doc: $0) }
    }

    //  MARK: - Today logs (read)
    func fetchTodayLogs(uid: String, date: Date = Date()) async throws -> [String: RoutineLog] {
        let day = DayKey.startOfDay(date)
        let snap = try await routineLogsRef(uid: uid)
            .whereField("date", isEqualTo: Timestamp(date: day))
            .getDocuments()

        var out: [String: RoutineLog] = [:]
        for d in snap.documents {
            if let log = Self.logFrom(doc: d) {
                out[log.routineId] = log
            }
        }
        return out
    }

    func reorderSteps(uid: String, routineId: String, newOrder: [String]) async throws {
        let batch = db.batch()
        for (idx, sid) in newOrder.enumerated() {
            let ref = stepsRef(uid: uid, routineId: routineId).document(sid)
            batch.updateData(["order": idx], forDocument: ref)
        }
        try await batch.commit()
        try await update(uid: uid, routineId: routineId, fields: [:])
    }

    //  MARK: - logs(toggle step for today)
    func toggleStepToday(uid: String, routineId: String, stepId: String, date: Date = Date()) async throws -> RoutineLog {
        let day = DayKey.startOfDay(date)
        let key = DayKey.key(day)
        let logId = "\(routineId)_\(key)"
        let logRef = routineLogsRef(uid: uid).document(logId)

        // Firestore's runTransaction closure must NOT throw.
        let any = try await db.runTransaction { (txn, errorPointer) -> Any? in
            // Read routine (for stepsTotal)
            let routineRef = self.routinesRef(uid: uid).document(routineId)
            let routineDoc: DocumentSnapshot
            do {
                routineDoc = try txn.getDocument(routineRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            let stepsTotal = (routineDoc.data()? ["stepsCount"] as? Int) ?? 0

            // Read existing log (if any)
            var completed: [String] = []
            var existed = false
            do {
                let logDoc = try txn.getDocument(logRef)
                if logDoc.exists, let d = logDoc.data() {
                    existed = true
                    completed = d["completedStepIds"] as? [String] ?? []
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            // Toggle step
            if let idx = completed.firstIndex(of: stepId) {
                completed.remove(at: idx)
            } else {
                completed.append(stepId)
            }
            let isCompleted = stepsTotal > 0 && completed.count >= stepsTotal

            let payload: [String: Any] = [
                "routineId": routineId,
                "date": Timestamp(date: day),
                "completedStepIds": completed,
                "stepsTotal": stepsTotal,
                "isCompleted": isCompleted
            ]

            if existed {
                txn.updateData(payload, forDocument: logRef)
            } else {
                txn.setData(payload, forDocument: logRef)
            }

            return RoutineLog(
                id: logId,
                routineId: routineId,
                date: day,
                completedStepIds: completed,
                stepsTotal: stepsTotal,
                isCompleted: isCompleted
            ) as Any
        }

        guard let log = any as? RoutineLog else {
            throw NSError(domain: "RoutineRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction failed or returned unexpected type"])
        }
        return log
    }

    //  MARK: - Mappers
    private static func routineFrom(doc: DocumentSnapshot) -> Routine? {
        guard let d = doc.data() else { return nil }
        let tsCreated = d["createdAt"] as? Timestamp
        let tsUpdated = d["updatedAt"] as? Timestamp

        return Routine(
            id: doc.documentID,
            title: d["title"] as? String ?? "",
            isActive: d["isActive"] as? Bool ?? true,
            daysOfWeek: d["daysOfWeek"] as? [Int] ?? [1,2,3,4,5,6,7],
            timeOfDay: d["timeOfDay"] as? String ?? "morning",
            reminderHour: d["reminderHour"] as? Int,
            reminderMinute: d["reminderMinute"] as? Int,
            stepsCount: d["stepsCount"] as? Int ?? 0,
            order: d["order"] as? Int ?? 0,
            createdAt: tsCreated?.dateValue() ?? Date(),
            updatedAt: tsUpdated?.dateValue() ?? Date()
        )
    }

    private static func stepFrom(doc: DocumentSnapshot) -> RoutineStep? {
        guard let d = doc.data() else { return nil }
        return RoutineStep(
            id: doc.documentID,
            title: d["title"] as? String ?? "",
            habitId: d["habitId"] as? String,
            order: d["order"] as? Int ?? 0,
            isOptional: d["isOptional"] as? Bool ?? false
        )
    }

    private static func logFrom(doc: DocumentSnapshot) -> RoutineLog? {
        guard let d = doc.data() else { return nil }
        let ts = d["date"] as? Timestamp
        return RoutineLog(
            id: doc.documentID,
            routineId: d["routineId"] as? String ?? "",
            date: ts?.dateValue() ?? Date(),
            completedStepIds: d["completedStepIds"] as? [String] ?? [],
            stepsTotal: d["stepsTotal"] as? Int ?? 0,
            isCompleted: d["isCompleted"] as? Bool ?? false
        )
    }
}
