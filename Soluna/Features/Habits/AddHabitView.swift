import SwiftUI

struct AddHabitView: View {
    @State var vm: HabitVM

    var body: some View {
        Form {
            TextField("Habit Title:", text: $vm.newTitle)
            Stepper("Target/Day: \(vm.targetPerDay)", value: $vm.targetPerDay, in: 1...10)
            Button("Save") {
                Task {
                    await vm.add()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Add Habit")
    }
}
