import WidgetKit
import SwiftUI

private let appGroupID = "group.com.saribal.Soluna"

private func currentStreak() -> Int {
    UserDefaults(suiteName: appGroupID)?.integer(forKey: "lastStreak") ?? 0
}

// MARK: - Entry
struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

// MARK: - Provider
struct StreakProvider: TimelineProvider {
    typealias Entry = StreakEntry
    
    func placeholder(in context: Context) -> StreakEntry {
        .init(date: .now, streak: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(.init(date: .now, streak: 5))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>)->()) {
        let entry = StreakEntry(date: .now, streak: currentStreak())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(1800))))
    }
}

// MARK: - View
struct StreakWidgetEntryView: View {
    var entry: StreakEntry
    var body: some View {
        VStack {
            Text("Streak").font(.headline)
            Text("\(entry.streak) 🔥").font(.largeTitle.bold())
        }
        .padding()
    }
}

// MARK: - Widget
struct StreakWidget: Widget {
    let kind = "Streak"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Your daily habit streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle
@main
struct SolunaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
    }
}
