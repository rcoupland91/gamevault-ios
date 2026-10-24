import SwiftUI
import StoreKit

// MARK: - Top-level Settings view (replaces ProfileView in the tab bar)

struct SettingsView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(ThemeManager.self) private var theme
    @AppStorage("app_mode") private var appModeRaw = "server"
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = true
    @State private var showLogoutConfirm = false
    @State private var showResetOnboarding = false

    private var appMode: AppMode { AppMode(rawValue: appModeRaw) ?? .server }

    var body: some View {
        NavigationStack {
            ZStack {
                settingsBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        accountSection
                        tipJarSection
                        settingsCategories
                        dangerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 76)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog("Sign Out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { authVM.logout() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You'll need to sign in again to access your library.") }
        .confirmationDialog("Restart Onboarding?", isPresented: $showResetOnboarding) {
            Button("Restart", role: .destructive) { hasCompletedOnboarding = false }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will take you back through the setup flow.") }
    }

    // MARK: - Tip Jar

    private var tipJarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Support")
            TipJarCard()
        }
    }

    // MARK: - Account

    @ViewBuilder
    private var accountSection: some View {
        VaultCard(cornerRadius: 30, padding: 20) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle().fill(theme.accentColor.opacity(0.15)).frame(width: 56, height: 56)
                        Text(String((authVM.currentUser?.username ?? (appMode == .local ? "Y" : "G")).prefix(1)).uppercased())
                            .font(.title3).fontWeight(.bold).foregroundStyle(theme.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authVM.currentUser?.username ?? (appMode == .local ? "Local User" : "Guest"))
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(authVM.currentUser?.email ?? (appMode == .local ? "App Only Mode" : "Not signed in"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    heroBadge(appMode == .local ? "App Only" : "Server Connected", icon: appMode == .local ? "iphone.gen3" : "server.rack")
                    if appMode == .server, !authVM.serverURL.isEmpty {
                        heroBadge("Configured", icon: "checkmark.circle.fill")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Settings Categories

    private var settingsCategories: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Preferences")
                VaultCard(padding: 0) {
                    VStack(spacing: 0) {
                        NavigationLink {
                            AppearanceSettingsView()
                                .environment(theme)
                        } label: {
                            SettingsNavRow(icon: "paintbrush.fill", title: "Appearance", subtitle: "Themes and display", color: .purple)
                                .padding(16)
                        }
                        Divider().padding(.leading, 62)
                        NavigationLink {
                            NotificationsSettingsView()
                        } label: {
                            SettingsNavRow(icon: "bell.fill", title: "Notifications", subtitle: "Reminders and alerts", color: .red)
                                .padding(16)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle(appMode == .server ? "Account" : "App Only")
                VaultCard(padding: 0) {
                    VStack(spacing: 0) {
                        if appMode == .server {
                            NavigationLink {
                                ServerSettingsView(authVM: authVM)
                            } label: {
                                SettingsNavRow(icon: "server.rack", title: "Server", subtitle: authVM.serverURL.isEmpty ? "Not configured" : authVM.serverURL, color: .indigo)
                                    .padding(16)
                            }
                            Divider().padding(.leading, 62)
                            NavigationLink {
                                AccountSecurityView(authVM: authVM)
                            } label: {
                                SettingsNavRow(icon: "lock.shield.fill", title: "Account & Security", subtitle: "Password, 2FA", color: .green)
                                    .padding(16)
                            }
                        } else {
                            NavigationLink {
                                GameSearchSettingsView()
                            } label: {
                                SettingsNavRow(
                                    icon: "key.fill",
                                    title: "Game Search",
                                    subtitle: RAWGDirectService.shared.hasApiKey ? "RAWG key configured" : "Tap to add RAWG API key",
                                    color: RAWGDirectService.shared.hasApiKey ? .green : .orange
                                )
                                .padding(16)
                            }
                            Divider().padding(.leading, 62)
                            NavigationLink {
                                iCloudSettingsView()
                            } label: {
                                SettingsNavRow(icon: "icloud.fill", title: "iCloud Sync", subtitle: "Sync across your Apple devices", color: .blue)
                                    .padding(16)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("About")
                VaultCard(padding: 0) {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsNavRow(icon: "info.circle.fill", title: "About GameVault", subtitle: "Version & licenses", color: .gray)
                            .padding(16)
                    }
                }
            }
        }
    }

    // MARK: - Danger

    @ViewBuilder
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Utilities")
            VaultCard(padding: 0) {
                VStack(spacing: 0) {
                    Button { showResetOnboarding = true } label: {
                        SettingsNavRow(icon: "arrow.trianglehead.2.counterclockwise.rotate.90", title: "Restart Onboarding", subtitle: "Walk through setup again", color: .teal)
                            .padding(16)
                    }
                    .buttonStyle(.plain)

                    if appMode == .server {
                        Divider().padding(.leading, 62)
                        Button(role: .destructive) { showLogoutConfirm = true } label: {
                            SettingsNavRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", subtitle: "Disconnect this account from the app", color: .red)
                                .padding(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var settingsBackground: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            Circle()
                .fill(theme.accentColor.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 46)
                .offset(x: -130, y: -260)

            Circle()
                .fill(theme.meshColors[4].opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 150, y: -160)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .tracking(0.8)
    }

    private func heroBadge(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.06))
        .clipShape(Capsule())
    }
}

// MARK: - Settings Nav Row

struct SettingsNavRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}

// MARK: - Tip Jar Card

private struct TipJarCard: View {
    @State private var vm = TipJarViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.title3).foregroundStyle(.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Support GameVault")
                        .font(.headline).fontWeight(.bold)
                    Text("Help keep the app free and improving")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if vm.thankYou {
                    Text("Thank you! ♥")
                        .font(.caption).fontWeight(.semibold).foregroundStyle(.pink)
                }
            }

            if vm.products.isEmpty {
                // Placeholder while loading or if not configured
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TipJarViewModel.placeholderTiers, id: \.label) { tier in
                            TipButton(label: tier.label, price: tier.price, isLoading: false) {}
                        }
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.products) { product in
                            TipButton(
                                label: product.displayName,
                                price: product.displayPrice,
                                isLoading: vm.isPurchasing
                            ) {
                                Task { await vm.purchase(product) }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.2), lineWidth: 1))
        .task { await vm.fetchProducts() }
    }
}

private struct TipButton: View {
    let label: String
    let price: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(price)
                    .font(.subheadline).fontWeight(.black)
                Text(label)
                    .font(.caption2).fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                LinearGradient(colors: [.pink, .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}

// MARK: - Tip Jar ViewModel

@Observable
final class TipJarViewModel {
    var products: [Product] = []
    var isPurchasing = false
    var thankYou = false

    static let placeholderTiers: [(label: String, price: String)] = [
        ("Coffee", "£0.99"), ("Small Tip", "£1.99"), ("Big Tip", "£4.99"),
        ("Generous", "£9.99"), ("Hero", "£19.99")
    ]

    private let productIds = [
        "com.gamevault.tip.coffee",
        "com.gamevault.tip.small",
        "com.gamevault.tip.big",
        "com.gamevault.tip.generous",
        "com.gamevault.tip.hero",
    ]

    func fetchProducts() async {
        guard let fetched = try? await Product.products(for: productIds) else { return }
        products = fetched.sorted { $0.price < $1.price }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        guard let result = try? await product.purchase() else { return }
        if case .success(let verification) = result,
           case .verified(let transaction) = verification {
            await transaction.finish()
            thankYou = true
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            thankYou = false
        }
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @Environment(ThemeManager.self) private var theme
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VaultCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Choose the tone of the app")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(AppTheme.allCases) { t in
                                AppearanceThemeSwatch(appTheme: t, isSelected: theme.currentTheme == t) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        theme.currentTheme = t
                                    }
                                }
                            }
                        }
                    }
                }

                VaultCard {
                    Label("Themes affect the accent color, background mood, and preferred light or dark presentation.", systemImage: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AppearanceThemeSwatch: View {
    let appTheme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(appTheme.previewGradient)
                        .frame(height: 56)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isSelected ? 2.5 : 1))
                    if isSelected { Image(systemName: "checkmark.circle.fill").foregroundStyle(.white).shadow(radius: 3) }
                }
                Text(appTheme.displayName).font(.caption2).fontWeight(isSelected ? .bold : .regular)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Notifications Settings

struct NotificationsSettingsView: View {
    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var requesting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultCard(cornerRadius: 24, padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label(statusText, systemImage: statusIcon)
                                .foregroundStyle(status == .authorized ? .green : .red)
                            Spacer()
                        }

                        if status == .notDetermined {
                            VaultButton(title: "Enable Notifications", icon: "bell.badge.fill", action: {
                                requesting = true
                                Task {
                                    _ = await NotificationService.shared.requestPermission()
                                    status = await NotificationService.shared.authorizationStatus
                                    requesting = false
                                }
                            }, isLoading: requesting)
                            .disabled(requesting)
                        } else {
                            VaultButton(title: "Open Notification Settings", icon: "gearshape.fill", action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }, style: .ghost)
                        }
                    }
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What Gets Sent")
                            .font(.headline)
                        Label("Review reminders — fired 3 days after completing a game with no review", systemImage: "star.bubble")
                        Label("Release alerts — fired on release day for wishlist games with a set date", systemImage: "calendar.badge.clock")
                    }
                    .font(.subheadline)
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { status = await NotificationService.shared.authorizationStatus }
    }

    private var statusText: String {
        switch status {
        case .authorized:    return "Notifications enabled"
        case .denied:        return "Notifications disabled"
        case .notDetermined: return "Not yet requested"
        default:             return "Unknown"
        }
    }
    private var statusIcon: String { status == .authorized ? "checkmark.circle.fill" : "xmark.circle.fill" }
}

// MARK: - Game Search Settings (local mode)

struct GameSearchSettingsView: View {
    @State private var apiKey = RAWGDirectService.shared.apiKey
    @State private var saved = false

    var body: some View {
        List {
            Section {
                SecureField("Paste your RAWG API key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Link("Get your free key at rawg.io/apidocs →",
                     destination: URL(string: "https://rawg.io/apidocs")!)
                    .font(.caption)
            } header: {
                Text("RAWG API Key")
            } footer: {
                Text("RAWG powers game search and metadata. Free accounts support 500,000 requests/month — more than enough for personal use.")
            }

            Section {
                Button(saved ? "Saved!" : "Save Key") {
                    RAWGDirectService.shared.apiKey = apiKey.trimmingCharacters(in: .whitespaces)
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                }
                .fontWeight(.semibold)
                .foregroundStyle(saved ? .green : Color.accentColor)
                .disabled(apiKey.isEmpty)
            }
        }
        .navigationTitle("Game Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - iCloud Settings (local mode)

struct iCloudSettingsView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Label("Sync Status", systemImage: "icloud.fill")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
                Button("Manage iCloud in Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } header: { Text("iCloud") }
              footer: { Text("Your library syncs automatically across all your Apple devices when iCloud is enabled. No account needed.") }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Server Settings (server mode)

struct ServerSettingsView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var showServerSetup = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("URL")
                    Spacer()
                    Text(authVM.serverURL.isEmpty ? "Not set" : authVM.serverURL)
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Button("Change Server URL") { showServerSetup = true }
            } header: { Text("Connection") }
        }
        .navigationTitle("Server")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showServerSetup) { ServerSetupView(authVM: authVM) }
    }
}

// MARK: - Account & Security (server mode)

struct AccountSecurityView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var showEditProfile = false
    @State private var showChangePassword = false
    @State private var show2FA = false

    var body: some View {
        List {
            Section("Profile") {
                Button("Edit Username") { showEditProfile = true }
                Button("Change Password") { showChangePassword = true }
                Button("Two-Factor Authentication") { show2FA = true }
            }
        }
        .navigationTitle("Account & Security")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditProfile) { EditProfileSheet(authVM: authVM) }
        .sheet(isPresented: $showChangePassword) { ChangePasswordSheet(authVM: authVM) }
        .sheet(isPresented: $show2FA) { TwoFactorView(authVM: authVM) }
    }
}

// MARK: - About

struct AboutView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultCard(cornerRadius: 26, padding: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("\(version) (\(build))").foregroundStyle(.secondary)
                        }
                        Link("Visit rawg.io for game data", destination: URL(string: "https://rawg.io")!)
                        Link("GitHub Repository", destination: URL(string: "https://github.com/rcoupland91/gamevault-ios")!)
                    }
                }

                VaultCard {
                    Text("Game data provided by RAWG. Built with SwiftUI for iOS.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
