import AppIntents

struct CompleteHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Habit"

    @Parameter(title: "Habit Title") var title: String

    func perform() async throws -> some IntentResult {
        let vm = HabitVM()
        await vm.load()
        if let habit = vm.habits.first(
            where: { $0.title.lowercased() == title.lowercased() }
        ) {
            await vm.tick(habit)
        }
        return .result()
    }
}


