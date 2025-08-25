import SwiftUI

struct Toast: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").imageScale(.large)
            Text(text).font(.subheadline).bold()
        }
        .foregroundStyle(.white)
        .padding(.vertical, 10).padding(.horizontal, 14)
        .background(.black.opacity(0.75), in: Capsule())
        .shadow(radius: 10, y: 6)
    }
}

extension View {
    func toast(_ text: String, isPresented: Binding<Bool>) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                VStack {
                    Spacer()
                    Toast(text: text).padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.25), value: isPresented.wrappedValue)
            }
        }
    }
}
