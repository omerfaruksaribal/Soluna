import SwiftUI

struct HabitListView: View {
    @State private var vm = HabitVM()

    var body: some View {
        List {
            ForEach(Array(vm.habits.enumerated()), id: \.offset) { _, habit in
                HStack {
                    VStack(alignment: .leading) {
                        Text(habit.title).bold()
                        Text("Target/day: \(habit.targetPerDay)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await vm.tick(habit) }
                    } label: {
                        Image(systemName: "checkmark.circle.fill").imageScale(.large)
                    }
                }
                .padding(12)
                .background(Styles.cardContainer())
            }
        }
        .scrollContentBackground(.hidden)
        .background(BrandColor.background)               
        .tint(BrandColor.primary)
        .task { await vm.load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Add") { AddHabitView(vm: vm) }
            }
        }
    }
}
