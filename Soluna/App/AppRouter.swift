import SwiftUI
import Observation
import FirebaseAuth

@Observable
final class SessionState {
    var isSignedIn = Auth.auth().currentUser != nil
}

struct AppRouter: View {
    @State private var session = SessionState()
    @AppStorage("themeMode") private var themeRaw = ThemeMode.system.rawValue

    var body: some View {
        let mode = ThemeMode(rawValue: themeRaw) ?? .system

        Group {
            if session.isSignedIn {
                TabView {
                    NavigationStack {
                        DashboardView()
                    }
                    .tabItem { Label("Home", systemImage: "square.grid.2x2") }

                    NavigationStack {
                        RoutineListView()
                    }
                    .tabItem { Label("Routines", systemImage: "checklist") }

                    NavigationStack {
                        ProfileView()
                    }
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                }
            } else {
                NavigationStack {
                    AuthView(onSignedIn: { session.isSignedIn = true })
                }
            }
        }
        .preferredColorScheme(mode.colorScheme)
        .tint(BrandColor.primary)
    }
}
