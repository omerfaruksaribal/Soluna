import Foundation
import WidgetKit

enum StreakSync {
    static let appGroupID = "group.com.saribal.Soluna"
    private static let key = "lastStreak"

    static func write(_ streak: Int) {
        let ud = UserDefaults(suiteName: appGroupID)
        ud?.set(streak, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: "streak")
    }

    static func read() -> Int {
        let ud = UserDefaults(suiteName: appGroupID)
        return ud?.integer(forKey: key) ?? 0
    }

    static func updateAfterTick(uid: String, habitId: String, logRepo: HabitLogRepository) async {
        do {
            let s = try await  logRepo.streak(uid: uid, habitId: habitId)
            write(s)
        } catch { }
    }
}
