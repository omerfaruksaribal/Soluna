import Observation
import FirebaseFirestore

@Observable
final class HabitVM {
    private let repo = HabitRepository()
    private let logRepo = HabitLogRepository()

    var habits: [Habit] = []
    var todayCounts: [String: Int] = [:]
    var newTitle: String = ""
    var targetPerDay: Int = 1
    var error: String?

    func load() async {
        guard let uid = await AuthService.shared.uid else { return }
        do {
            habits = try await repo.fetchAll(uid: uid)
            todayCounts = try await logRepo.todayCounts(uid: uid)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func add() async {
        guard let uid = await AuthService.shared.uid, !newTitle.isEmpty else { return }
        do {
            _ = try await repo.add(uid: uid, title: newTitle, targetPerDay: targetPerDay)
            newTitle = ""
            targetPerDay = 1
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func tick(_ habit: Habit) async {
        guard let uid = await AuthService.shared.uid, let id = habit.id else { return }
        do {
            let c = todayCounts[id] ?? 0
            if c >= habit.targetPerDay {
                return
            }

            try await logRepo.tick(uid: uid, habitId: id)
            todayCounts = try await logRepo.todayCounts(uid: uid)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func progress(for habit: Habit) -> (count: Int, target: Int, done: Bool, ratio: Double) {
        let id = habit.id ?? ""
        let count = todayCounts[id] ?? 0
        let target = max(1, habit.targetPerDay)
        let ratio = min(1.0, Double(count) / Double(target))
        return (count, target, count >= target, ratio)
    }
}
