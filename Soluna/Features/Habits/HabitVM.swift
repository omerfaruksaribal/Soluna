import Observation
import FirebaseFirestore

@Observable
final class HabitVM {
    private let repo = HabitRepository()
    private let logRepo = HabitLogRepository()

    var habits: [Habit] = []
    var newTitle: String = ""
    var targetPerDay: Int = 1
    var error: String?

    func load() async {
        guard let uid = await AuthService.shared.uid else { return }
        do { habits = try await repo.fetchAll(uid: uid) }
        catch { self.error = error.localizedDescription }
    }

    func add() async {
        guard let uid = await AuthService.shared.uid, !newTitle.isEmpty else { return }
        do {
            _ = try await repo.add(uid: uid, title: newTitle, targetPerDay: targetPerDay)
            await load()
            newTitle = ""; targetPerDay = 1
        } catch { self.error = error.localizedDescription }
    }

    func tick(_ habit: Habit) async {
        guard let uid = await AuthService.shared.uid, let id = habit.id else { return }
        do { try await logRepo.tick(uid: uid, habitId: id) }
        catch { self.error = error.localizedDescription }
    }
}
