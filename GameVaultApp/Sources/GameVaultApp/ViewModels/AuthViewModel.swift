import Foundation
import SwiftUI
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var error: String?

    // Login
    @Published var loginInput = ""
    @Published var loginPassword = ""

    // Register
    @Published var registerUsername = ""
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerConfirmPassword = ""

    // 2FA
    @Published var requires2FA = false
    @Published var preToken = ""
    @Published var twoFACode = ""
    @Published var twoFAMethods: TwoFAMethods?
    @Published var selected2FAMethod = "totp"
    @Published var otpResentSuccess = false

    // Server
    @Published var serverURL = UserDefaults.standard.string(forKey: "server_url") ?? ""
    @Published var showServerSetup = false

    // OIDC
    @Published var publicSettings: PublicSettings?

    private let auth = AuthService.shared
    private var webAuthSession: ASWebAuthenticationSession?
    private let contextProvider = OIDCPresentationContext()

    init() {
        isLoggedIn = auth.isLoggedIn
        Task {
            if isLoggedIn { await loadCurrentUser() }
            await loadPublicSettings()
        }
    }

    // MARK: - Login

    func login() async {
        guard !serverURL.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please configure your server URL first."
            showServerSetup = true
            return
        }

        isLoading = true
        error = nil

        do {
            let response = try await auth.login(login: loginInput, password: loginPassword)

            if response.requires2FA == true {
                preToken = response.preToken ?? ""
                twoFAMethods = response.methods
                selected2FAMethod = (response.methods?.totp == true) ? "totp" : "email"
                requires2FA = true
            } else if let user = response.user {
                currentUser = user
                isLoggedIn = true
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - 2FA Verify

    func verify2FA() async {
        isLoading = true
        error = nil

        do {
            let response = try await auth.verify2FA(preToken: preToken, code: twoFACode, method: selected2FAMethod)
            if let user = response.user {
                currentUser = user
                isLoggedIn = true
                requires2FA = false
                twoFACode = ""
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func resendEmailOTP() async {
        do {
            try await auth.resendEmailOTP(preToken: preToken)
            otpResentSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.otpResentSuccess = false
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Register

    func register() async {
        guard registerPassword == registerConfirmPassword else {
            error = "Passwords do not match"
            return
        }
        guard registerPassword.count >= 8 else {
            error = "Password must be at least 8 characters"
            return
        }

        isLoading = true
        error = nil

        do {
            let response = try await auth.register(username: registerUsername, email: registerEmail, password: registerPassword)
            if let user = response.user {
                currentUser = user
                isLoggedIn = true
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Profile

    func loadCurrentUser() async {
        do {
            currentUser = try await auth.me()
        } catch {
            if case APIServiceError.unauthorized = error {
                logout()
            }
        }
    }

    func updateProfile(username: String? = nil, currentPassword: String? = nil, newPassword: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        currentUser = try await auth.updateProfile(username: username, currentPassword: currentPassword, newPassword: newPassword)
    }

    func togglePasswordLogin(disabled: Bool) async throws {
        let result = try await auth.togglePasswordLogin(disabled: disabled)
        currentUser?.passwordLoginDisabled = result
    }

    // MARK: - Logout

    func logout() {
        Task {
            try? await auth.logout()
        }
        auth.clearSession()
        currentUser = nil
        isLoggedIn = false
        requires2FA = false
        loginInput = ""
        loginPassword = ""
        twoFACode = ""
    }

    // MARK: - Server URL

    func saveServerURL() {
        let trimmed = serverURL.trimmingCharacters(in: .whitespaces)
        APIService.shared.baseURL = trimmed
        showServerSetup = false
        Task { await loadPublicSettings() }
    }

    func loadPublicSettings() async {
        guard !serverURL.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            publicSettings = try await auth.fetchPublicSettings()
        } catch {
            // Non-critical — silently ignore
        }
    }

    // MARK: - OIDC Login

    func loginWithOIDC() async {
        guard !serverURL.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please configure your server URL first."
            showServerSetup = true
            return
        }

        let baseURL = APIService.shared.baseURL
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let loginURL = URL(string: "\(baseURL)/api/auth/oidc/login") else {
            error = "Invalid server URL"
            return
        }

        isLoading = true
        error = nil

        let session = ASWebAuthenticationSession(
            url: loginURL,
            callbackURLScheme: "gamevault"
        ) { [weak self] callbackURL, sessionError in
            guard let self else { return }
            Task { @MainActor in
                self.isLoading = false
                if let sessionError {
                    // User cancelled — not an error worth showing
                    if (sessionError as? ASWebAuthenticationSessionError)?.code != .canceledLogin {
                        self.error = sessionError.localizedDescription
                    }
                    return
                }
                guard let callbackURL else {
                    self.error = "No callback URL received"
                    return
                }
                self.handleOIDCCallback(url: callbackURL)
            }
        }
        session.presentationContextProvider = contextProvider
        session.prefersEphemeralWebBrowserSession = false
        webAuthSession = session
        session.start()
    }

    func handleOIDCCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        if url.host == "auth" && url.path == "/error" {
            let message = components.queryItems?.first(where: { $0.name == "message" })?.value ?? "Authentication failed"
            error = message
            return
        }

        guard url.host == "auth" && url.path == "/callback",
              let access = components.queryItems?.first(where: { $0.name == "access" })?.value,
              let refresh = components.queryItems?.first(where: { $0.name == "refresh" })?.value else {
            error = "Invalid OIDC callback"
            return
        }

        auth.storeOIDCTokens(access: access, refresh: refresh)
        isLoading = true
        Task {
            await loadCurrentUser()
            isLoggedIn = true
            isLoading = false
        }
    }
}

// MARK: - OIDC Presentation Context

final class OIDCPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}
