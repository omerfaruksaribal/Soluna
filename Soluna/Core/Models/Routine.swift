import Foundation

struct Routine: Identifiable, Hashable {
    let id: String
    var title: String
    var isActive: Bool

    /// 1=Mon, 7=Sun (will use Calendar.current.weekdaySymbols)
    var daysOfWeek: [Int]

    /// "morning", "afternoon", "evening", "custom"
    var timeOfDay: String

    /// Optional daily remind time (hh:mm)
    var reminderHour: Int?
    var reminderMinute: Int?

    var stepsCount: Int
    var order: Int
    var createdAt: Date
    var updatedAt: Date
}

struct RoutineStep: Identifiable, Hashable {
    let id: String
    var title: String

    ///  a step can match with habit (optional)
    var habitId: String?

    var order: Int
    var isOptional: Bool
}

struct RoutineLog: Identifiable, Hashable {
    /// id = "\(routineId)_\(dayKey)"
    let id: String
    let routineId: String
    let date: Date // Start of day
    var completedStepIds: [String]
    var stepsTotal: Int
    var isCompleted: Bool
}
