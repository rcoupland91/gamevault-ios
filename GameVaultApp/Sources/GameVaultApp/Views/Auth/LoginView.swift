import SwiftUI

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(ThemeManager.self) private var theme
    @State private var showRegister = false
    @State private var logoScale = 0.7
    @State private var contentOffset = 40.0
    @State private var contentOpacity = 0.0

    var body: some View {
        ZStack {
            loginBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 60)

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.regularMaterial)
                                .frame(width: 108, height: 108)
                                .overlay(Circle().stroke(theme.accentColor.opacity(0.2), lineWidth: 1.5))
                                .shadow(color: theme.accentColor.opacity(0.25), radius: 24)
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(theme.accentColor)
                        }
                        .scaleEffect(logoScale)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.05), value: logoScale)

                        VStack(spacing: 4) {
                            Text("GameVault")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                            Text("Sign in to your library")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 8) {
                            loginBadge("Self-hosted friendly", icon: "server.rack")
                            loginBadge("Beautiful local mode", icon: "iphone.gen3")
                        }
                    }

                    VStack(spacing: 14) {
                        VaultCard(cornerRadius: 28, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Account")
                                    .font(.headline)

                                VaultTextField(
                                    placeholder: "Email or username",
                                    text: $authVM.loginInput,
                                    icon: "person",
                                    autocapitalization: .never,
                                    autocorrect: false
                                )
                                VaultTextField(
                                    placeholder: "Password",
                                    text: $authVM.loginPassword,
                                    isSecure: true,
                                    icon: "lock"
                                )

                                if let error = authVM.error {
                                    ErrorBanner(message: error) { authVM.error = nil }
                                }

                                VaultButton(
                                    title: "Sign In",
                                    icon: "arrow.right",
                                    action: { Task { await authVM.login() } },
                                    isLoading: authVM.isLoading
                                )
                            }
                        }

                        if let settings = authVM.publicSettings, settings.oidcEnabled {
                            VaultCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        VStack { Divider() }
                                        Text("or").font(.caption).foregroundStyle(.secondary)
                                        VStack { Divider() }
                                    }
                                    Button {
                                        Task { await authVM.loginWithOIDC() }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "person.badge.key.fill")
                                            Text("Continue with \(settings.oidcDisplayName)")
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(.regularMaterial)
                                        .foregroundStyle(.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                        )
                                    }
                                    .disabled(authVM.isLoading)
                                }
                            }
                        }
                    }

                    Button { authVM.showServerSetup = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "server.rack").font(.caption)
                            Text(authVM.serverURL.isEmpty ? "Configure Server" : authVM.serverURL)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                    }

                    // Register
                    HStack {
                        Text("New to GameVault?").foregroundStyle(.secondary).font(.subheadline)
                        Button("Create Account") { showRegister = true }
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.accentColor)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
                    .offset(y: contentOffset)
            .opacity(contentOpacity)
        }
        .sheet(isPresented: $showRegister) { RegisterView(authVM: authVM) }
        .sheet(isPresented: $authVM.showServerSetup) { ServerSetupView(authVM: authVM) }
        .sheet(isPresented: $authVM.requires2FA) { TwoFactorView(authVM: authVM) }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                logoScale = 1
                contentOffset = 0
                contentOpacity = 1
            }
        }
        .task { await authVM.loadPublicSettings() }
    }

    private var loginBackground: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            Circle()
                .fill(theme.accentColor.opacity(0.15))
                .frame(width: 280, height: 280)
                .blur(radius: 48)
                .offset(x: -130, y: -260)

            Circle()
                .fill(Color.blue.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 160, y: -150)
        }
    }

    private func loginBadge(_ title: String, icon: String) -> some View {
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

// MARK: - Register View

struct RegisterView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                Circle()
                    .fill(theme.accentColor.opacity(0.12))
                    .frame(width: 240, height: 240)
                    .blur(radius: 40)
                    .offset(x: -120, y: -260)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 52))
                                .foregroundStyle(theme.accentColor)
                                .padding(.top, 12)
                            Text("Create Account")
                                .font(.title2).fontWeight(.bold)
                            Text("Join GameVault and start tracking")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }

                        VaultCard(cornerRadius: 28, padding: 18) {
                            VStack(spacing: 14) {
                                VaultTextField(placeholder: "Username", text: $authVM.registerUsername, icon: "person", autocapitalization: .never, autocorrect: false)
                                VaultTextField(placeholder: "Email", text: $authVM.registerEmail, icon: "envelope", keyboardType: .emailAddress, autocapitalization: .never, autocorrect: false)
                                VaultTextField(placeholder: "Password (min 8 chars)", text: $authVM.registerPassword, isSecure: true, icon: "lock")
                                VaultTextField(placeholder: "Confirm Password", text: $authVM.registerConfirmPassword, isSecure: true, icon: "lock.shield")

                                if let error = authVM.error {
                                    ErrorBanner(message: error) { authVM.error = nil }
                                }

                                VaultButton(title: "Create Account", icon: "person.badge.plus", action: {
                                    Task { await authVM.register() }
                                }, isLoading: authVM.isLoading)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
