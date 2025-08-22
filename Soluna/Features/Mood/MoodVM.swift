import Observation
import FirebaseFirestore

@Observable
final class MoodVM {
    private let repo = MoodRepository()

    var moods: [MoodEntry] = []
    var note: String = ""
    var selectedMood: String = "neutral"
    var loading = false
    var error: String?

    func load() async {
        guard let uid = await AuthService.shared.uid else { return }
        loading = true; defer { loading = false }
        do { moods = try await repo.fetchRecent(uid: uid) }
        catch { self.error = error.localizedDescription }
    }

    func add() async {
        guard let uid = await AuthService.shared.uid else { return }
        do {
            let new = try await repo.add(uid: uid, mood: selectedMood, note: note)
            moods.insert(new, at: 0)
            note = ""; selectedMood = "neutral"
        } catch { self.error = error.localizedDescription }
    }
}
