import SwiftUI
import UserNotifications

struct ProfileView: View {
    // Theme Settings
    @AppStorage("themeMode") private var themeRaw = ThemeMode.system.rawValue

    // Notification Settings
    @AppStorage("streakReminderEnabled") private var reminderEnabled: Bool = false
    @AppStorage("streakReminderHour")    private var reminderHour: Int = 20
    @AppStorage("streakReminderMinute")  private var reminderMinute: Int = 0

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var tempTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: Binding(
                        get: { ThemeMode(rawValue: themeRaw) ?? .system },
                        set: { themeRaw = $0.rawValue }
                    )) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Daily Streak Reminder")) {
                    Toggle("Enable reminder", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, on in
                            Task { await ensurePermissionAndSchedule(enabled: on) }
                        }

                    DatePicker("Reminder time", selection: $tempTime, displayedComponents: .hourAndMinute)
                        .onChange(of: tempTime) { _, newVal in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newVal)
                            reminderHour = comps.hour ?? 20
                            reminderMinute = comps.minute ?? 0
                            Task {
                                await NotificationService.scheduleDailyStreak(hour: reminderHour, minute: reminderMinute, enabled: reminderEnabled)
                            }
                        }
                        .disabled(!reminderEnabled)

                    HStack {
                        Text("Permission")
                        Spacer()
                        Text(statusText(authStatus))
                            .foregroundStyle(authStatus == .authorized ? .green : .secondary)
                    }

                    Button("Request Permission") { Task { authStatus = await NotificationService.requestAuthorization() } }

                    Button("Send Test Notification") { Task { await NotificationService.fireTest() } }
                }

                Section(header: Text("Account")) {
                    Button(role: .destructive) {
                        Task {
                            try? await AuthService.shared.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Profile")
        }
        .onAppear {
            if let d = Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) {
                tempTime = d
            }
            Task { authStatus = await NotificationService.requestAuthorization() }
        }
    }

    private func ensurePermissionAndSchedule(enabled: Bool) async {
        if enabled {
            let status = await NotificationService.requestAuthorization()
            authStatus = status
            let allow = (status == .authorized || status == .provisional || status == .ephemeral)
            await NotificationService.scheduleDailyStreak(hour: reminderHour, minute: reminderMinute, enabled: allow)
            if !allow { reminderEnabled = false }
        } else {
            await NotificationService.cancelDailyStreak()
        }
    }

    private func statusText(_ s: UNAuthorizationStatus) -> String {
        switch s {
        case .authorized:   return "Authorized"
        case .denied:       return "Denied"
        case .notDetermined:return "Not Determined"
        case .provisional:  return "Provisional"
        case .ephemeral:    return "Ephemeral"
        @unknown default:   return "Unknown"
        }
    }
}
