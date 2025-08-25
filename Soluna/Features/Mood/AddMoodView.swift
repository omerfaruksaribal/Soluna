import SwiftUI

struct AddMoodView: View {
    @State var vm: MoodVM
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false

    // call for toast
    var onAdded: (() -> Void)? = nil

    init(vm: MoodVM, onAdded: (() -> Void)? = nil) {
        _vm = State(initialValue: vm)
        self.onAdded = onAdded
    }

    var body: some View {
        Form {
            Section("Mood") {
                Picker("Select", selection: $vm.selectedMood) {
                    Text("Happy").tag("happy")
                    Text("Neutral").tag("neutral")
                    Text("Sad").tag("sad")
                }.pickerStyle(.segmented)
                TextField("Note (optional)", text: $vm.note, axis: .vertical)
            }
            Section {
                Button(isSaving ? "Saving…" : "Save") {
                    Task {
                        guard !isSaving else { return }
                        isSaving = true
                        await vm.add()
                        Haptics.success()
                        onAdded?()
                        isSaving = false
                        dismiss()
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("Add Mood")
        .scrollContentBackground(.hidden)
        .background(BrandColor.background)
    }
}
