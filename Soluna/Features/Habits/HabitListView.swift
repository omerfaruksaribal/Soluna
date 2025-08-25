import SwiftUI

struct HabitListView: View {
    @State private var vm = HabitVM()
    @State private var showAddedToast = false

    var body: some View {
        List {
            ForEach(Array(vm.habits.enumerated()), id: \.offset) { _, habit in
                let progress = vm.progress(for: habit)
                HabitRow(
                    habit: habit,
                    progress: progress,
                    onTick: { Task { await vm.tick(habit) } },
                    onToggleActive: { Task { await vm.toggleActive(habit) } },
                    onEdit: { vm.beginEdit(habit) }
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(BrandColor.background)
        .tint(BrandColor.primary)
        .task { await vm.load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Add") {
                    AddHabitView(vm: vm)
                    { showAddedToast = false }
                }
            }
        }
        .toast("Habit Added", isPresented: $showAddedToast)
        
        // Edit Sheet
        .sheet(isPresented: Binding(
            get: { vm.editingHabit != nil },
            set: { if !$0 { vm.editingHabit = nil } })
        ) {
            EditHabitSheet(vm: vm)
        }
    }

private struct HabitRow: View {
    let habit: Habit
    let progress: (count: Int, target: Int, done: Bool, ratio: Double)
    let onTick: () -> Void
    let onToggleActive: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ProgressRing(progress: progress.ratio, size: 28)
                .foregroundStyle(BrandColor.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title).bold()
                Text("\(progress.count) / \(progress.target) today")
                    .font(.caption)
                    .foregroundStyle(progress.done ? .green : .secondary)
            }
            Spacer()
            Button(action: onTick) {
                Image(systemName: progress.done ? "checkmark.circle" : "checkmark.circle.fill")
                    .imageScale(.large)
            }
            .disabled(progress.done || !habit.isActive)
            .opacity((progress.done || !habit.isActive) ? 0.35 : 1.0)
        }
        .padding(12)
        .contentShape(Rectangle())
        .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Styles.cardRowBackground())
        .contextMenu {
            Button(habit.isActive ? "Deactivate" : "Activate", action: onToggleActive)
            Button("Edit", action: onEdit)
        }
        .swipeActions {
            Button(habit.isActive ? "Deactivate" : "Activate", action: onToggleActive)
                .tint(habit.isActive ? .orange : .green)
            Button("Edit", action: onEdit)
                .tint(.blue)
        }
    }
}
}

//  MARK: - Edit Sheet
private struct EditHabitSheet: View {
    @State var vm: HabitVM

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Habit title", text: $vm.editTitle)
                }
                Section("Daily target") {
                    Stepper("Per day: \(vm.editTarget)", value: $vm.editTarget, in: 1...20)
                }
                if let e = vm.error {
                    Text(e).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle("Edit Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.editingHabit = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await vm.saveEdit() }
                    }
                    .disabled(vm.editTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
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
