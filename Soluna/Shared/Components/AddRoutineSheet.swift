import SwiftUI

struct AddRoutineSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedDays: Set<Int> = [1,2,3,4,5,6,7]   // 1=Mon ... 7=Sun
    @State private var timeOfDay = "morning"
    @State private var customTimeLabel = ""
    @State private var reminderOn = false
    @State private var reminder = Date()

    let onSave: (_ title: String, _ days: Set<Int>, _ timeOfDay: String, _ reminder: Date?) -> Void

    private let timeOptions = ["morning","afternoon","evening","custom"]
    private let symbols = Calendar.current.shortWeekdaySymbols // ["Sun","Mon",...]

    var body: some View {
        NavigationStack {
            Form {
                // TITLE
                Section("Title") {
                    TextField("Routine title", text: $title)
                }

                // DAYS
                Section("Days of week") {
                    // 1...7 (Mon..Sun) ekranda Tue..Mon gösteriyoruz
                    let mapIndex: [Int] = [2,3,4,5,6,7,1]
                    HStack(spacing: 8) {
                        ForEach(mapIndex, id: \.self) { day in
                            let isOn = selectedDays.contains(day)
                            Button {
                                if isOn { selectedDays.remove(day) } else { selectedDays.insert(day) }
                            } label: {
                                Text(symbols[day % 7])
                                    .font(.callout.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(isOn ? BrandColor.card : .clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(.quaternary, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain) // Form satır tap’leriyle çakışmasın
                        }
                    }

                    Button(selectedDays.count == 7 ? "Clear All" : "Select All") {
                        if selectedDays.count == 7 {
                            selectedDays.removeAll()
                        } else {
                            selectedDays = [1,2,3,4,5,6,7]
                        }
                    }
                    .buttonStyle(.borderless)
                }

                // TIME OF DAY
                Section("Time of day") {
                    Picker("Time", selection: $timeOfDay) {
                        ForEach(timeOptions, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    if timeOfDay == "custom" {
                        TextField("Custom label (e.g. Night)", text: $customTimeLabel)
                            .textInputAutocapitalization(.words)
                    }
                }

                // REMINDER
                Section("Reminder") {
                    Toggle("Enable", isOn: $reminderOn)
                    if reminderOn {
                        DatePicker("Time", selection: $reminder, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("New Routine")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // custom seçildiyse etiketi kullan, boşsa "custom"
                        let finalTime = timeOfDay == "custom"
                        ? (customTimeLabel.trimmingCharacters(in: .whitespaces).isEmpty
                           ? "custom"
                           : customTimeLabel.trimmingCharacters(in: .whitespaces))
                        : timeOfDay

                        onSave(title, selectedDays, finalTime, reminderOn ? reminder : nil)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }
}
