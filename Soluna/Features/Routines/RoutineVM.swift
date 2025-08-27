import Foundation
import FirebaseFirestore

@MainActor
final class RoutineVM: ObservableObject {
    @Published var routines: [Routine] = []
    @Published var stepsByRoutine: [String: [RoutineStep]] = [:]   // routineId -> steps
    @Published var todayLogs: [String: RoutineLog] = [:]           // routineId -> log
    @Published var error: String?

    private let repo = RoutineRepository()

    //  MARK: - Load All
    func load() async {
        guard let uid = AuthService.shared.uid else { return }

        do {
            // Routines
            let items = try await repo.fetchAll(uid: uid)
            self.routines = items

            // Steps (parrarel)
            var dict: [String: [RoutineStep]] = [:]
            for r in items {
                dict[r.id] = try await repo.fetchSteps(uid: uid, routineId: r.id)
            }
            self.stepsByRoutine = dict

            // Today logs
            self.todayLogs = try await repo.fetchTodayLogs(uid: uid)
        } catch {
            self.error = error.localizedDescription
        }
    }

    //  MARK: - Progress Helpers
    func progress(for r: Routine) -> (count: Int, total: Int, ratio: Double, done: Bool) {
        let total = r.stepsCount
        let count = todayLogs[r.id]?.completedStepIds.count ?? 0
        let ratio = total > 0 ? Double(count) / Double(total) : 0
        return (count, total, ratio, total > 0 && count >= total)
    }

    //  MARK: - Toggle step today
    func toggleStep(routineId: String, stepId: String) async {
        do {
            guard let uid = AuthService.shared.uid else { return }
            let log = try await repo.toggleStepToday(uid: uid, routineId: routineId, stepId: stepId)
            todayLogs[routineId] = log
        } catch {
            self.error = error.localizedDescription
        }
    }

    //  MARK: - Add / Delete Snap
    func addStep(routineId: String, title: String) async {
        do {
            guard let uid = AuthService.shared.uid else { return }
            let order = (stepsByRoutine[routineId]?.count ?? 0)
            _ = try await repo.addStep(uid: uid, routineId: routineId, title: title, habitId: nil, order: order)
            stepsByRoutine[routineId] = try await repo.fetchSteps(uid: uid, routineId: routineId)
            // stepsCount değiştiği için routines’i da tazele
            routines = try await repo.fetchAll(uid: uid)
            // logu da güncellemek için yeniden çekelim (opsiyonel)
            todayLogs = try await repo.fetchTodayLogs(uid: uid)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteStep(routineId: String, stepId: String) async {
        do {
            guard let uid = AuthService.shared.uid else { return }
            try await repo.deleteStep(uid: uid, routineId: routineId, stepId: stepId)
            stepsByRoutine[routineId] = try await repo.fetchSteps(uid: uid, routineId: routineId)
            routines = try await repo.fetchAll(uid: uid)
            todayLogs = try await repo.fetchTodayLogs(uid: uid)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Reorder
    func reorder(routineId: String, newOrder: [RoutineStep]) async {
        do {
            guard let uid = AuthService.shared.uid else { return }
            try await repo.reorderSteps(uid: uid, routineId: routineId, newOrder: newOrder.map { $0.id })
            stepsByRoutine[routineId] = try await repo.fetchSteps(uid: uid, routineId: routineId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createRoutine(
        title: String,
        days: Set<Int>,
        timeOfDay: String,
        reminder: Date?
    ) async {
        do {
            guard let uid = AuthService.shared.uid else { return }

            let comps = reminder.map { Calendar.current.dateComponents([.hour, .minute], from: $0) }
            let newId = try await repo.create(
                uid: uid,
                title: title,
                daysOfWeek: Array(days).sorted(),
                timeOfDay: timeOfDay,
                reminderHour: comps?.hour,
                reminderMinute: comps?.minute,
                order: routines.count
            )

            // update the list (dont need to refetch)
            let now = Date()
            let newItem = Routine(
                id: newId,
                title: title,
                isActive: true,
                daysOfWeek: Array(days).sorted(),
                timeOfDay: timeOfDay,
                reminderHour: comps?.hour,
                reminderMinute: comps?.minute,
                stepsCount: 0,
                order: routines.count,
                createdAt: now,
                updatedAt: now
            )
            routines.append(newItem)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteRoutine(_ r: Routine) async {
        do {
            guard let uid = AuthService.shared.uid else { return }
            try await repo.delete(uid: uid, routineId: r.id)
            routines.removeAll { $0.id == r.id }
            stepsByRoutine[r.id] = nil
            todayLogs[r.id] = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
