import SwiftUI

struct HabitListView: View {
    @State private var vm = HabitVM()

    var body: some View {
        List {
            ForEach(Array(vm.habits.enumerated()), id: \.offset) { _, habit in
                let p = vm.progress(for: habit)

                HStack(spacing: 12) {
                    ProgressRing(progress: p.ratio, size: 28)
                        .foregroundStyle(BrandColor.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.title).bold()
                        Text("\(p.count) / \(p.target) today")
                            .font(.caption).foregroundStyle(p.done ? .green : .secondary)
                    }
                    Spacer()
                    Button {
                        Task { await vm.tick(habit) }
                    } label: {
                        Image(systemName: p.done ? "checkmark.circle" : "checkmark.circle.fill")
                            .imageScale(.large)
                    }
                    .disabled(p.done)
                    .opacity(p.done ? 0.4 : 1.0)
                }
                .padding(12)
                .background(Styles.cardContainer())
            }
        }
        .listStyle(.plain)
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

private struct ProgressRing: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(lineWidth: 4).opacity(0.15)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)
        }
        .frame(width: size, height: size)
    }
}
