import SwiftUI
import Charts

struct DashboardView: View {
    @State private var tab: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $tab) {
                Text("Mood").tag(0)
                Text("Habits").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if tab == 0 { MoodListView() } else { HabitListView() }
        }
        .navigationTitle("Soluna")
        .tint(BrandColor.primary)                    // accent
        .background(BrandColor.background.ignoresSafeArea())
    }
}
