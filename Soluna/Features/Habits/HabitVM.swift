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

    // Edit sheet state
   var editingHabit: Habit?
   var editTitle: String = ""
   var editTarget: Int = 1

    func load() async {
        guard let uid = await AuthService.shared.uid else { return }
        do {
            habits = try await repo.fetchAll(uid: uid)
            todayCounts = try await logRepo.todayCounts(uid: uid)
        } catch { self.error = error.localizedDescription }
    }

    func add() async {
        guard let uid = await AuthService.shared.uid, !newTitle.isEmpty else { return }
        do {
            _ = try await repo.add(uid: uid, title: newTitle, targetPerDay: targetPerDay)
            newTitle = ""; targetPerDay = 1
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func tick(_ habit: Habit) async {
        guard let uid = await AuthService.shared.uid else { return }
        do {
            let newCount = try await logRepo.tickCapped(uid: uid, habit: habit)
            if let id = habit.id { todayCounts[id] = newCount }
            Haptics.success()
        } catch let he as HabitError where he == .targetReached {
            Haptics.impact()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleActive(_ habit: Habit) async {
        guard let uid = await AuthService.shared.uid, let id = habit.id else { return }
        do {
            try await repo.setActive(uid: uid, habitId: id, isActive: !habit.isActive)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func beginEdit(_ habit: Habit) {
        editingHabit = habit
        editTitle = habit.title
        editTarget = habit.targetPerDay
    }

    func saveEdit() async {
        guard let uid = await AuthService.shared.uid,
              let habit = editingHabit,
              let id = habit.id else { return }
        do {
            try await repo.update(uid: uid, habitId: id, title: editTitle, targetPerDay: editTarget)
            editingHabit = nil
            await load()
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
