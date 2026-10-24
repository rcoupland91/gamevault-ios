import SwiftUI

@main
struct GameVaultApp: App {
    @State private var themeManager = ThemeManager()
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @AppStorage("app_mode") private var appModeRaw = "server"
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding, themeManager: themeManager)
                } else {
                    RootView(authVM: authVM, appMode: AppMode(rawValue: appModeRaw) ?? .server)
                }
            }
            .environment(themeManager)
            .tint(themeManager.accentColor)
            .preferredColorScheme(themeManager.colorScheme)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: hasCompletedOnboarding)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @ObservedObject var authVM: AuthViewModel
    let appMode: AppMode

    var body: some View {
        Group {
            if appMode == .local {
                MainTabView(authVM: authVM)
            } else if authVM.isLoggedIn {
                MainTabView(authVM: authVM)
                    .transition(.asymmetric(
                        insertion: .push(from: .trailing),
                        removal: .push(from: .leading)
                    ))
            } else {
                LoginView(authVM: authVM)
                    .transition(.asymmetric(
                        insertion: .push(from: .leading),
                        removal: .push(from: .trailing)
                    ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: authVM.isLoggedIn)
        .task {
            _ = await NotificationService.shared.requestPermission()
        }
    }
}
