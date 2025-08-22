import WidgetKit
import SwiftUI

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

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(date: .now, streak: 7)
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
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
