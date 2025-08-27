import SwiftUI

struct RoutineDetailView: View {
    @ObservedObject var vm: RoutineVM
    let routine: Routine

    @State private var newStepTitle = ""

    private var steps: [RoutineStep] { vm.stepsByRoutine[routine.id] ?? [] }
    private var log: RoutineLog? { vm.todayLogs[routine.id] }

    var body: some View {
        List {
            Section {
                let p = vm.progress(for: routine)
                HStack(spacing: 12) {
                    MiniProgressRing(progress: p.ratio, size: 28)
                        .foregroundStyle(BrandColor.primary)
                    VStack(alignment: .leading) {
                        Text("\(p.count) of \(p.total) today")
                            .font(.callout)
                        ProgressView(value: p.ratio)
                    }
                }
                .padding(8)
                .background(Styles.cardContainer())
                .listRowBackground(BrandColor.background)
            }

            Section("Steps") {
                ForEach(steps) { step in
                    let isDone = log?.completedStepIds.contains(step.id) ?? false
                    HStack {
                        Button {
                            Task { await vm.toggleStep(routineId: routine.id, stepId: step.id) }
                        } label: {
                            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)

                        Text(step.title)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(Styles.cardContainer())
                    .listRowBackground(BrandColor.background)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await vm.deleteStep(routineId: routine.id, stepId: step.id) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
                .onMove { indices, newOffset in
                    var copy = steps
                    copy.move(fromOffsets: indices, toOffset: newOffset)
                    Task { await vm.reorder(routineId: routine.id, newOrder: copy) }
                }

                HStack {
                    TextField("New step", text: $newStepTitle)
                    Button("Add") {
                        let title = newStepTitle.trimmingCharacters(in: .whitespaces)
                        guard !title.isEmpty else { return }
                        Task {
                            await vm.addStep(routineId: routine.id, title: title)
                            newStepTitle = ""
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(BrandColor.background)
        .navigationTitle(routine.title)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(routine.title)
                    .font(.headline)
            }
        }
        .toolbar { EditButton() }
        .task {
            if vm.stepsByRoutine[routine.id] == nil {
                await vm.load()
            }
        }
    }
}
