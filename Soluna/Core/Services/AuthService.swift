import FirebaseAuth

@MainActor
final class AuthService {
    static let shared = AuthService()
    private init() {}

    var uid: String? { Auth.auth().currentUser?.uid }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signOut() async throws {
         try Auth.auth().signOut()
    }
}
