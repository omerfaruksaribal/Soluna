import SwiftUI

struct AddHabitView: View {
    @State var vm: HabitVM
    @Environment(\.dismiss) var dismiss
    @State private var isSaving = false
    var onAdded: (() -> Void)? = nil

    var body: some View {
        Form {
            Section("Title") {
                TextField("Habit Title:", text: $vm.newTitle)
            }

            Section("Daily Target") {
                Stepper("Target/Day: \(vm.targetPerDay)", value: $vm.targetPerDay, in: 1...10)
            }

            Section() {
                Button(isSaving ? "Saving..." : "Save") {
                    Task {
                        guard !isSaving else { return }
                        isSaving = false
                        await vm.add()
                        Haptics.success()
                        onAdded?()
                        isSaving = false
                        dismiss()
                    }
                }
                .disabled(isSaving || vm.newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Add Habit")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Add Habit")
                    .font(.headline)
            }
        }
        .scrollContentBackground(.hidden)
    }
}
