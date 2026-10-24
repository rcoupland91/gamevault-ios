import SwiftUI

struct ProfileView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(ThemeManager.self) private var theme
    @AppStorage("app_mode") private var appModeRaw = "server"
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = true

    @State private var showEditProfile = false
    @State private var showChangePassword = false
    @State private var show2FASetup = false
    @State private var showServerSetup = false
    @State private var showLogoutConfirm = false
    @State private var showResetOnboarding = false
    @State private var showLocalSettings = false

    private var appMode: AppMode { AppMode(rawValue: appModeRaw) ?? .server }
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    profileHeader
                    themeSection
                    if appMode == .server { serverSection } else { localSettingsSection }
                    appSection
                    dangerSection
                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showEditProfile) { EditProfileSheet(authVM: authVM) }
        .sheet(isPresented: $showChangePassword) { ChangePasswordSheet(authVM: authVM) }
        .sheet(isPresented: $showServerSetup) { ServerSetupView(authVM: authVM) }
        .sheet(isPresented: $showLocalSettings) { LocalSettingsSheet() }
        .confirmationDialog("Sign Out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { authVM.logout() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You'll need to sign in again to access your library.") }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VaultCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(theme.accentColor.opacity(0.15)).frame(width: 64, height: 64)
                    if let avatarUrl = authVM.currentUser?.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: { avatarInitial }
                        .frame(width: 64, height: 64).clipShape(Circle())
                    } else { avatarInitial }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(authVM.currentUser?.username ?? (appMode == .local ? "Local User" : "Guest"))
                        .font(.title3).fontWeight(.bold)
                    Text(authVM.currentUser?.email ?? (appMode == .local ? "App Only Mode" : "Not signed in"))
                        .font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Image(systemName: appMode == .local ? "iphone" : "server.rack").font(.caption2)
                        Text(appMode == .local ? "App Only" : "Server").font(.caption2).fontWeight(.medium)
                    }
                    .foregroundStyle(theme.accentColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(theme.accentColor.opacity(0.1)).clipShape(Capsule())
                }
                Spacer()
                if appMode == .server {
                    Button { showEditProfile = true } label: {
                        Image(systemName: "pencil").font(.subheadline).foregroundStyle(theme.accentColor)
                            .frame(width: 34, height: 34).background(theme.accentColor.opacity(0.1)).clipShape(Circle())
                    }
                }
            }
        }
    }

    private var avatarInitial: some View {
        Text(String((authVM.currentUser?.username ?? "G").prefix(1)).uppercased())
            .font(.title2).fontWeight(.bold).foregroundStyle(theme.accentColor)
    }

    // MARK: - Theme

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPEARANCE")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).tracking(0.8)
            VaultCard(padding: 14) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(AppTheme.allCases) { t in
                        ThemeSwatch(theme: t, isSelected: theme.currentTheme == t) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                theme.currentTheme = t
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Server / Account

    private var serverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACCOUNT")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).tracking(0.8)
            VaultCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(icon: "lock.fill", title: "Change Password", color: .blue) { showChangePassword = true }.padding(16)
                    Divider().padding(.leading, 62)
                    SettingsRow(icon: "shield.fill", title: "Two-Factor Auth", color: .green) { show2FASetup = true }.padding(16)
                    Divider().padding(.leading, 62)
                    SettingsRow(icon: "server.rack", title: "Server Settings", subtitle: authVM.serverURL.isEmpty ? "Not configured" : authVM.serverURL, color: .indigo) { showServerSetup = true }.padding(16)
                }
            }
        }
        .sheet(isPresented: $show2FASetup) { TwoFactorView(authVM: authVM) }
    }

    // MARK: - Local Mode Settings

    private var localSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SETTINGS")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).tracking(0.8)
            VaultCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(icon: "key.fill", title: "RAWG API Key", subtitle: RAWGDirectService.shared.hasApiKey ? "Configured" : "Required for game search", color: RAWGDirectService.shared.hasApiKey ? .green : .orange) {
                        showLocalSettings = true
                    }.padding(16)
                    Divider().padding(.leading, 62)
                    SettingsRow(icon: "icloud.fill", title: "iCloud Sync", subtitle: "Syncs your library across Apple devices", color: .blue) {
                        showLocalSettings = true
                    }.padding(16)
                    Divider().padding(.leading, 62)
                    SettingsRow(icon: "bell.fill", title: "Notifications", color: .red) {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }.padding(16)
                }
            }
        }
    }

    // MARK: - App

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APP")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).tracking(0.8)
            VaultCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(icon: "bell.fill", title: "Notification Settings", color: .red) {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }.padding(16)
                    Divider().padding(.leading, 62)
                    SettingsRow(icon: "arrow.trianglehead.2.counterclockwise.rotate.90", title: "Restart Onboarding", color: .teal) { showResetOnboarding = true }.padding(16)
                }
            }
        }
        .confirmationDialog("Restart Onboarding?", isPresented: $showResetOnboarding) {
            Button("Restart", role: .destructive) { hasCompletedOnboarding = false }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will take you back through the setup flow.") }
    }

    // MARK: - Danger

    @ViewBuilder
    private var dangerSection: some View {
        if appMode == .server {
            VaultCard(padding: 0) {
                Button { showLogoutConfirm = true } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                            .frame(width: 32, height: 32).background(Color.red).clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("Sign Out").font(.subheadline).foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Theme Swatch

private struct ThemeSwatch: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.previewGradient)
                        .frame(height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isSelected ? 2.5 : 1)
                        )
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 3)
                    }
                }
                Text(theme.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Username") {
                    TextField("Username", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Edit Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            do {
                                try await authVM.updateProfile(username: username.isEmpty ? nil : username)
                                dismiss()
                            } catch { self.error = error.localizedDescription }
                            isSaving = false
                        }
                    }
                    .fontWeight(.semibold).disabled(isSaving)
                }
            }
            .onAppear { username = authVM.currentUser?.username ?? "" }
        }
    }
}

// MARK: - Local Settings Sheet

struct LocalSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rawgKey = RAWGDirectService.shared.apiKey
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    @State private var requestingNotifs = false

    var body: some View {
        NavigationStack {
            Form {
                // RAWG API Key
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SecureField("Paste your RAWG API key", text: $rawgKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            if !rawgKey.isEmpty {
                                Button { rawgKey = "" } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                                }
                            }
                        }
                        Text("Required for searching games in App Only mode.")
                            .font(.caption).foregroundStyle(.secondary)
                        Link("Get your free key at rawg.io/apidocs →",
                             destination: URL(string: "https://rawg.io/apidocs")!)
                            .font(.caption).foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Text("RAWG API Key")
                } footer: {
                    Text("RAWG provides game artwork, metadata, and search. Free accounts support up to 500,000 requests/month.")
                }

                // iCloud
                Section("iCloud Sync") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync via iCloud")
                            Text("Your library syncs automatically when iCloud is enabled.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Button("Manage iCloud in Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // Notifications
                Section("Notifications") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Status")
                            Text(notifStatusText).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: notifStatusIcon)
                            .foregroundStyle(notifStatusColor)
                    }

                    if notifStatus == .notDetermined {
                        Button("Enable Notifications") {
                            requestingNotifs = true
                            Task {
                                _ = await NotificationService.shared.requestPermission()
                                notifStatus = await NotificationService.shared.authorizationStatus
                                requestingNotifs = false
                            }
                        }
                        .disabled(requestingNotifs)
                    } else {
                        Button("Open Notification Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Review reminders after completing a game", systemImage: "star.bubble")
                        Label("Release alerts for wishlist games", systemImage: "calendar.badge.clock")
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        RAWGDirectService.shared.apiKey = rawgKey.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                notifStatus = await NotificationService.shared.authorizationStatus
            }
        }
    }

    private var notifStatusText: String {
        switch notifStatus {
        case .authorized:    return "Enabled"
        case .denied:        return "Disabled — open Settings to enable"
        case .notDetermined: return "Not yet requested"
        default:             return "Unknown"
        }
    }

    private var notifStatusIcon: String {
        notifStatus == .authorized ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private var notifStatusColor: Color {
        notifStatus == .authorized ? .green : .red
    }
}

// MARK: - Change Password Sheet

struct ChangePasswordSheet: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var newPass = ""
    @State private var confirm = ""
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Password") { SecureField("Current password", text: $current) }
                Section("New Password") {
                    SecureField("New password", text: $newPass)
                    SecureField("Confirm new password", text: $confirm)
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Change Password").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard newPass == confirm else { error = "Passwords don't match"; return }
                        guard newPass.count >= 8 else { error = "Min 8 characters"; return }
                        isSaving = true
                        Task {
                            do {
                                try await authVM.updateProfile(currentPassword: current, newPassword: newPass)
                                dismiss()
                            } catch { self.error = error.localizedDescription }
                            isSaving = false
                        }
                    }
                    .fontWeight(.semibold).disabled(isSaving || current.isEmpty || newPass.isEmpty)
                }
            }
        }
    }
}
