import SwiftUI

// MARK: - Onboarding Container

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    let themeManager: ThemeManager

    // Always-dark gradient so white text stays legible regardless of chosen theme
    static let darkMeshColors: [Color] = [
        Color(hex: "0D0D1A"), Color(hex: "1A0D2E"), Color(hex: "0D1A2E"),
        Color(hex: "1A1A2E"), Color(hex: "2D1040"), Color(hex: "1A2E3D"),
        Color(hex: "0D0D1A"), Color(hex: "1A1A2E"), Color(hex: "0D1A2E")
    ]

    @State private var page = 0
    @State private var selectedMode: AppMode = .server
    @State private var notificationsEnabled = false
    @AppStorage("app_mode") private var appModeRaw = "server"

    private let totalPages = 5

    var body: some View {
        ZStack {
            // Onboarding always uses a rich dark background for legibility
            OnboardingBackground(colors: OnboardingView.darkMeshColors)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    WelcomePage().tag(0)
                    ModePage(selectedMode: $selectedMode).tag(1)
                    ConnectionPage(mode: selectedMode).tag(2)
                    ThemePage(themeManager: themeManager).tag(3)
                    NotificationsPage(enabled: $notificationsEnabled).tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: page)

                // Bottom nav
                OnboardingFooter(
                    page: page,
                    totalPages: totalPages,
                    canAdvance: canAdvance,
                    onNext: advance,
                    onFinish: finish
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var canAdvance: Bool { true }

    private func advance() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            page = min(page + 1, totalPages - 1)
        }
    }

    private func finish() {
        appModeRaw = selectedMode.rawValue
        if notificationsEnabled {
            Task { await NotificationService.shared.requestPermission() }
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Animated Mesh Background

private struct OnboardingBackground: View {
    let colors: [Color]
    @State private var animate = false

    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: animate ? [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.6, 0.4], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ] : [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.4, 0.6], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: colors
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)
                    .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                    .shadow(color: .black.opacity(0.3), radius: 30)

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10)
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1), value: appeared)

            VStack(spacing: 12) {
                Text("GameVault")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appeared)

                Text("Track what you play.\nRemember what it meant.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appeared)
            }

            HStack(spacing: 8) {
                welcomeBadge("App Only", icon: "iphone.gen3")
                welcomeBadge("Server Sync", icon: "server.rack")
                welcomeBadge("Themes", icon: "paintbrush")
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: appeared)

            // Feature pills
            VStack(spacing: 10) {
                ForEach([
                    ("books.vertical.fill", "Track every game you play"),
                    ("chart.bar.fill", "See your habits at a glance"),
                    ("bell.badge.fill", "Get nudges for reviews and releases"),
                ], id: \.0) { icon, text in
                    FeaturePill(icon: icon, text: text)
                        .offset(y: appeared ? 0 : 30)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: appeared)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear { appeared = true }
    }

    private func welcomeBadge(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.white.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct FeaturePill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Page 2: Mode Selection

private struct ModePage: View {
    @Binding var selectedMode: AppMode
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text("How do you play?")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Choose how you want to use GameVault")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appeared)

            VStack(spacing: 14) {
                ModeCard(
                    icon: "server.rack",
                    title: "GameVault Server",
                    subtitle: "Connect to your self-hosted GameVault instance. Full sync, multi-device, community features.",
                    isSelected: selectedMode == .server,
                    accentColor: .indigo
                ) { selectedMode = .server }

                ModeCard(
                    icon: "iphone",
                    title: "App Only",
                    subtitle: "No server needed. Store your library on-device with optional iCloud sync across your Apple devices.",
                    isSelected: selectedMode == .local,
                    accentColor: .teal
                ) { selectedMode = .local }
            }
            .offset(y: appeared ? 0 : 30)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appeared)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { appeared = true }
    }
}

private struct ModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? accentColor : .white.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? accentColor : .white.opacity(0.4))
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? accentColor.opacity(0.8) : .white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.18 : 0.08), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Page 3: Connection / iCloud

private struct ConnectionPage: View {
    let mode: AppMode
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            if mode == .server {
                ServerConnectionContent()
            } else {
                iCloudContent()
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { appeared = true }
    }
}

private struct ServerConnectionContent: View {
    @State private var serverURL = UserDefaults.standard.string(forKey: "server_url") ?? ""
    @State private var tested = false
    @State private var testing = false
    @State private var testResult: String?
    @State private var testSuccess = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10)
                Text("Connect your server")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Enter the URL of your GameVault instance.\nYou can skip this and set it up later.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "link").foregroundStyle(.white.opacity(0.6))
                    TextField("http://192.168.1.100:3000", text: $serverURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                        .tint(.white)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.2), lineWidth: 1))

                if let result = testResult {
                    HStack(spacing: 8) {
                        Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(testSuccess ? .green : .red)
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(testSuccess ? .green : .red)
                    }
                }

                Button {
                    guard !serverURL.isEmpty else { return }
                    APIService.shared.baseURL = serverURL
                    UserDefaults.standard.set(serverURL, forKey: "server_url")
                    testing = true
                    Task {
                        struct H: Decodable { let status: String? }
                        do {
                            let _: H = try await APIService.shared.request("/health", retryOnUnauthorized: false)
                            testResult = "Connected successfully!"
                            testSuccess = true
                        } catch {
                            testResult = "Could not connect. Check URL."
                            testSuccess = false
                        }
                        testing = false
                    }
                } label: {
                    HStack {
                        if testing { ProgressView().tint(.white).scaleEffect(0.8) }
                        else { Image(systemName: "wifi") }
                        Text(testing ? "Testing…" : "Test Connection")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(serverURL.isEmpty ? .white.opacity(0.1) : .white.opacity(0.2))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(serverURL.isEmpty || testing)
                .animation(.spring(response: 0.3), value: testing)
            }
        }
    }
}

private struct iCloudContent: View {
    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 16) {
                Image(systemName: "icloud.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 12)

                Text("iCloud Sync")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your game library syncs automatically across all your Apple devices using iCloud — iPhone, iPad, and Mac.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach([
                    ("iphone.and.ipad", "Works across all your devices"),
                    ("lock.shield.fill", "Private — only you can see your data"),
                    ("arrow.trianglehead.2.clockwise", "Syncs automatically in the background"),
                ], id: \.0) { icon, text in
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(width: 28)
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Text("Make sure iCloud is enabled in your iPhone Settings to use sync.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Page 4: Theme

private struct ThemePage: View {
    let themeManager: ThemeManager
    @State private var appeared = false

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Make it yours")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Choose a theme")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeSwatchButton(theme: theme, isSelected: themeManager.currentTheme == theme) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            themeManager.currentTheme = theme
                        }
                    }
                }
            }
            .offset(y: appeared ? 0 : 30)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { appeared = true }
    }
}

private struct ThemeSwatchButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.previewGradient)
                        .frame(height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? .white : .white.opacity(0.2), lineWidth: isSelected ? 2.5 : 1)
                        )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title3)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                }

                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Page 5: Notifications

private struct NotificationsPage: View {
    @Binding var enabled: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 12)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)

                VStack(spacing: 8) {
                    Text("Stay in the loop")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("GameVault can remind you to leave reviews and alert you when wishlist games release.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
            }

            VStack(spacing: 12) {
                NotificationFeatureRow(icon: "star.bubble.fill", title: "Review reminders", subtitle: "Nudge to rate games after you finish them")
                NotificationFeatureRow(icon: "calendar.badge.clock", title: "Release alerts", subtitle: "Get notified when wishlist games drop")
            }
            .offset(y: appeared ? 0 : 30)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)

            Toggle(isOn: $enabled) {
                Text("Enable notifications")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .tint(.white)
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: appeared)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { appeared = true }
    }
}

private struct NotificationFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - Footer Nav

private struct OnboardingFooter: View {
    let page: Int
    let totalPages: Int
    let canAdvance: Bool
    let onNext: () -> Void
    let onFinish: () -> Void

    private var isLast: Bool { page == totalPages - 1 }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Step \(page + 1) of \(totalPages)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(isLast ? "Ready to start" : "Keep going")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }

            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? .white : .white.opacity(0.3))
                        .frame(width: i == page ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: page)
                }
            }

            Button(action: isLast ? onFinish : onNext) {
                HStack(spacing: 8) {
                    Text(isLast ? "Let's Go" : "Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                    Image(systemName: isLast ? "arrow.right.circle.fill" : "arrow.right")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(.black)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.5)
            .animation(.spring(response: 0.3), value: isLast)
            .sensoryFeedback(.impact(weight: .medium), trigger: page)
        }
    }
}
