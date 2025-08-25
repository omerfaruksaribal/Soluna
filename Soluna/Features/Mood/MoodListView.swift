import SwiftUI
import Charts

struct MoodListView: View {
    @State private var vm = MoodVM()
    @State private var showAddedToast = false

    var body: some View {
        List {
            Section {
                Chart(chartData, id: \.date) { item in
                    LineMark(x: .value("Date", item.date), y: .value("Mood", item.score))
                    PointMark(x: .value("Date", item.date), y: .value("Mood", item.score))
                }
                .frame(height: 160)
            } header: {
                Text("2-Week Trend")
            }

            Section("Entries") {
                ForEach(vm.moods) { mood in
                    VStack(alignment: .leading, spacing: 6) {
                        emoji(mood.mood) + Text("  ") + Text(mood.mood.capitalized).bold()
                        if let note = mood.note, !note.isEmpty {
                            Text(note)
                        }
                        Text(mood.date, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(Styles.cardContainer())
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BrandColor.background)  
        .task {
            await vm.load()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Add") {
                    AddMoodView(vm: vm) { showAddedToast = true }
                }
            }
        }
        .toast("Mood added", isPresented: $showAddedToast)
    }

    // Precomputed data for the chart to help the compiler
    private var chartData: [(date: Date, score: Int)] {
        vm.moods.prefix(14).map { (date: $0.date, score: moodScore($0.mood)) }
    }

    private func emoji(_ m: String) -> Text {
        Text(["happy":"😄","neutral":"🙂","sad":"😕"][m, default:"🙂"])
    }

    private func moodScore(_ mood: String) -> Int {
        ["sad": 0, "neutral": 1, "happy": 2][mood, default: 1]
    }
}
