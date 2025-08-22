import SwiftUI

struct AddMoodView: View {
    @State var vm: MoodVM

    var body: some View {
        Form {
            Picker("Mood", selection: $vm.selectedMood) {
                Text("😄 Happy").tag("happy")
                Text("🙂 Neutral").tag("neutral")
                Text("😕 Sad").tag("sad")
            }
            TextField("Note (optional)", text: $vm.note)
            Button("Save") { Task { await vm.add() } }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Add Mood")
    }
}
