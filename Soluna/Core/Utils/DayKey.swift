import Foundation

enum DayKey {
    static func startOfDay(_ d: Date) -> Date {
        Calendar.current.startOfDay(for: d)
    }

    static func key(_ d: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: startOfDay(d))
    }
}
