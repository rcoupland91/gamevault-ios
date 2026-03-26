import Foundation

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let api = APIService.shared
    private let keychain = KeychainService.shared

    // MARK: - Register

    struct RegisterRequest: Encodable {
        let username: String
        let email: String
        let password: String
    }

    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        let body = RegisterRequest(username: username, email: email, password: password)
        let response: AuthResponse = try await api.request("/auth/register", method: .post, body: body, retryOnUnauthorized: false)
        storeTokens(from: response)
        return response
    }

    // MARK: - Login

    struct LoginRequest: Encodable {
        let login: String
        let password: String
    }

    func login(login: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(login: login, password: password)
        let response: AuthResponse = try await api.request("/auth/login", method: .post, body: body, retryOnUnauthorized: false)
        if response.requires2FA != true {
            storeTokens(from: response)
        }
        return response
    }

    // MARK: - 2FA Verify

    struct TwoFAVerifyRequest: Encodable {
        let preToken: String
        let code: String
        let method: String
    }

    func verify2FA(preToken: String, code: String, method: String) async throws -> AuthResponse {
        let body = TwoFAVerifyRequest(preToken: preToken, code: code, method: method)
        let response: AuthResponse = try await api.request("/auth/2fa/verify", method: .post, body: body, retryOnUnauthorized: false)
        storeTokens(from: response)
        return response
    }

    // MARK: - Resend Email OTP

    struct ResendOTPRequest: Encodable {
        let preToken: String
    }

    func resendEmailOTP(preToken: String) async throws {
        let body = ResendOTPRequest(preToken: preToken)
        let _: EmptyResponse = try await api.request("/auth/2fa/resend", method: .post, body: body, retryOnUnauthorized: false)
    }

    // MARK: - Get Current User

    func me() async throws -> User {
        return try await api.request("/auth/me")
    }

    // MARK: - Update Profile

    struct ProfileUpdateRequest: Encodable {
        let username: String?
        let avatarUrl: String?
        let currentPassword: String?
        let newPassword: String?

        enum CodingKeys: String, CodingKey {
            case username
            case avatarUrl = "avatar_url"
            case currentPassword = "current_password"
            case newPassword = "new_password"
        }
    }

    func updateProfile(username: String? = nil, avatarUrl: String? = nil, currentPassword: String? = nil, newPassword: String? = nil) async throws -> User {
        let body = ProfileUpdateRequest(username: username, avatarUrl: avatarUrl, currentPassword: currentPassword, newPassword: newPassword)
        return try await api.request("/auth/profile", method: .patch, body: body)
    }

    // MARK: - Logout

    func logout() async throws {
        let _: EmptyResponse = try await api.request("/auth/logout", method: .post)
        clearSession()
    }

    func clearSession() {
        keychain.clearAll()
    }

    // MARK: - 2FA Management

    func get2FAStatus() async throws -> TwoFAStatus {
        return try await api.request("/auth/2fa/status", method: .post)
    }

    struct TOTPSetupResponse: Codable {
        let secret: String?
        let qrCodeUrl: String?
        let otpauthUrl: String?

        enum CodingKeys: String, CodingKey {
            case secret
            case qrCodeUrl = "qr_code_url"
            case otpauthUrl = "otpauth_url"
        }
    }

    func setupTOTP() async throws -> TOTPSetupResponse {
        return try await api.request("/auth/2fa/totp/setup", method: .post)
    }

    struct TOTPConfirmRequest: Encodable {
        let token: String
    }

    struct TOTPConfirmResponse: Codable {
        let backupCodes: [String]?
        enum CodingKeys: String, CodingKey {
            case backupCodes = "backup_codes"
        }
    }

    func confirmTOTP(token: String) async throws -> TOTPConfirmResponse {
        let body = TOTPConfirmRequest(token: token)
        return try await api.request("/auth/2fa/totp/confirm", method: .post, body: body)
    }

    struct PasswordConfirmRequest: Encodable {
        let password: String
    }

    func disableTOTP(password: String) async throws {
        let body = PasswordConfirmRequest(password: password)
        let _: EmptyResponse = try await api.request("/auth/2fa/totp/disable", method: .post, body: body)
    }

    func toggleEmailOTP(enabled: Bool, password: String) async throws {
        struct ToggleRequest: Encodable { let enabled: Bool; let password: String }
        let body = ToggleRequest(enabled: enabled, password: password)
        let _: EmptyResponse = try await api.request("/auth/2fa/email/toggle", method: .post, body: body)
    }

    // MARK: - Password Login Toggle

    struct PasswordLoginToggleResponse: Codable {
        let passwordLoginDisabled: Bool
        enum CodingKeys: String, CodingKey {
            case passwordLoginDisabled = "password_login_disabled"
        }
    }

    func togglePasswordLogin(disabled: Bool) async throws -> Bool {
        struct ToggleRequest: Encodable { let disabled: Bool }
        let body = ToggleRequest(disabled: disabled)
        let response: PasswordLoginToggleResponse = try await api.request("/auth/password-login/toggle", method: .post, body: body)
        return response.passwordLoginDisabled
    }

    // MARK: - Public Settings

    func fetchPublicSettings() async throws -> PublicSettings {
        return try await api.request("/settings/public", retryOnUnauthorized: false)
    }

    // MARK: - OIDC Token Storage

    func storeOIDCTokens(access: String, refresh: String) {
        keychain.save(access, for: .accessToken)
        keychain.save(refresh, for: .refreshToken)
    }

    // MARK: - Helpers

    var isLoggedIn: Bool {
        keychain.load(.accessToken) != nil || keychain.load(.refreshToken) != nil
    }

    private func storeTokens(from response: AuthResponse) {
        if let access = response.access {
            keychain.save(access, for: .accessToken)
        }
        if let refresh = response.refresh {
            keychain.save(refresh, for: .refreshToken)
        }
        if let userId = response.user?.id {
            keychain.save(userId, for: .userId)
        }
    }
}
