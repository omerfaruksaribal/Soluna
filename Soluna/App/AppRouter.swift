import SwiftUI
import Observation
import FirebaseAuth

@Observable
final class SessionState {
    var isSignedIn = Auth.auth().currentUser != nil
}

struct AppRouter: View {
    @State private var session = SessionState()

    var body: some View {
        NavigationStack {
            if session.isSignedIn {
                DashboardView()
                    .toolbar {
                        Button("Log Out") {
                            try? Auth.auth().signOut()
                            session.isSignedIn = false
                        }
                    }
            } else {
                AuthView(onSignedIn: { session.isSignedIn = true } )
            }
        }
        .tint(BrandColor.primary)
    }
}
