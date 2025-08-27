import SwiftUI

struct RoutineListView: View {
    @StateObject private var vm = RoutineVM()
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.routines.isEmpty {
                    EmptyState {
                        showAdd = true
                    }
                    .padding(.horizontal, 24)
                } else {
                    List {
                        ForEach(vm.routines) { r in
                            let p = vm.progress(for: r)
                            NavigationLink {
                                RoutineDetailView(vm: vm, routine: r)
                            } label: {
                                HStack(spacing: 12) {
                                    MiniProgressRing(progress: p.ratio, size: 28)
                                        .foregroundStyle(BrandColor.primary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(r.title).bold()
                                        Text("Today \(p.count) / \(r.stepsCount)")
                                            .font(.caption)
                                            .foregroundStyle(p.done ? .green : .secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(12)
                                .background(Styles.cardContainer())
                            }
                            .contentShape(Rectangle()) // tüm hücre tıklanabilir
                            .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(BrandColor.background)
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task { await vm.deleteRoutine(r) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(BrandColor.background)
                }
            }
            .navigationTitle("Routines")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: { Image(systemName: "plus") }
                }
            }
            .task { await vm.load() }
        }
        .tint(BrandColor.primary)
        .sheet(isPresented: $showAdd) {
            AddRoutineSheet { title, days, timeOfDay, reminder in
                Task {
                    await vm.createRoutine(
                        title: title,
                        days: days,
                        timeOfDay: timeOfDay,
                        reminder: reminder
                    )
                }
            }
        }
    }
}

private struct EmptyState: View {
    var onAdd: () -> Void
    init(onAdd: @escaping () -> Void) { self.onAdd = onAdd }
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No routines yet")
                .font(.title3.bold())
            Text("Create a routine and break it into small steps. Check off steps every day.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Create Routine", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(Styles.cardContainer())
    }
}
