import SwiftUI

struct AuthView: View {
    var onSignedIn: () -> Void

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var error: String?
    @FocusState private var focusedField: Field?

    enum Mode { case signIn, signUp }
    enum Field { case email, password }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red:0.08, green:0.09, blue:0.18),
                         Color(red:0.02, green:0.02, blue:0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    VStack(spacing: 6) {
                        Text("Soluna")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(radius: 20, y: 10)

                        Text(mode == .signIn ? "Welcome back" : "Create your account")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    // Toggle
                    HStack(spacing: 8) {
                        SegButton(title: "Sign In", isSelected: mode == .signIn) { mode = .signIn }
                        SegButton(title: "Sign Up", isSelected: mode == .signUp) { mode = .signUp }
                    }
                    .padding(.horizontal)

                    // Glass Card
                    VStack(spacing: 14) {
                        IconField(system: "envelope.fill", placeholder: "sample@email.com", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)

                        IconSecureField(system: "lock.fill", placeholder: "Password",
                                        text: $password, show: $showPassword)
                            .focused($focusedField, equals: .password)
                    }
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 30, y: 18)
                    .padding(.horizontal)

                    // Action
                    Button(action: submit) {
                        Text(mode == .signIn ? "Sign In" : "Create Account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
                    .padding(.horizontal)

                    if let e = error {
                        Text(e).font(.footnote).foregroundStyle(.red.opacity(0.9))
                            .padding(.horizontal)
                    }

                    // Secondary
                    Button(role: .none) {
                        mode = (mode == .signIn ? .signUp : .signIn)
                    } label: {
                        Text(mode == .signIn ? "No account? Sign Up" : "Have an account? Sign In")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                            .underline()
                    }
                    .padding(.bottom, 30)
                }
                .padding(.vertical, 30)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { focusedField = nil }
        }
    }

    private func submit() {
        Task {
            do {
                if mode == .signIn {
                    try await AuthService.shared.signIn(email: email, password: password)
                } else {
                    try await AuthService.shared.signUp(email: email, password: password)
                }
                onSignedIn()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Components

private struct SegButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(isSelected ? 0.25 : 0.08), lineWidth: 1)
                )
                .foregroundStyle(.white)
        }
    }
}

private struct IconField: View {
    let system: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: system)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.7))
            TextField(placeholder, text: $text)
                .foregroundStyle(.white)
                .tint(.white)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct IconSecureField: View {
    let system: String
    let placeholder: String
    @Binding var text: String
    @Binding var show: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: system)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.7))

            if show {
                TextField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .tint(.white)
            } else {
                SecureField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .tint(.white)
            }

            Button { show.toggle() } label: {
                Image(systemName: show ? "eye.slash.fill" : "eye.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}
