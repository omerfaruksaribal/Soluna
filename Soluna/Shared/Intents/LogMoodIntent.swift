import AppIntents

struct LogMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Log mood"
    @Parameter(title: "Mood", default: "happy") var mood: String

    func perform() async throws -> some IntentResult {
        let vm = MoodVM()
        vm.selectedMood = mood
        await vm.add()
        return .result()
    }
}
