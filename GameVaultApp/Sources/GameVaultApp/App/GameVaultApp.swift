import SwiftUI

@main
struct GameVaultApp: App {
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("appearance_mode") private var appearanceMode = "system"

    var body: some Scene {
        WindowGroup {
            RootView(authVM: authVM)
                .preferredColorScheme(colorScheme(for: appearanceMode))
        }
    }

    private func colorScheme(for mode: String) -> ColorScheme? {
        switch mode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
}

struct RootView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                MainTabView(authVM: authVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                LoginView(authVM: authVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: authVM.isLoggedIn)
    }
}
