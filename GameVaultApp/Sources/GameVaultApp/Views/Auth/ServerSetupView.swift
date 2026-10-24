import SwiftUI

struct ServerSetupView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme
    @State private var isTestingConnection = false
    @State private var connectionResult: String?
    @State private var connectionSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        VaultCard(cornerRadius: 30, padding: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(theme.accentColor.opacity(0.16))
                                            .frame(width: 58, height: 58)
                                        Image(systemName: "server.rack")
                                            .font(.title2.weight(.bold))
                                            .foregroundStyle(theme.accentColor)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Server Setup")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("Point GameVault at your self-hosted instance and verify the connection before signing in.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                VaultTextField(
                                    placeholder: "http://192.168.1.100:3000",
                                    text: $authVM.serverURL,
                                    icon: "link",
                                    keyboardType: .URL,
                                    autocapitalization: .never,
                                    autocorrect: false
                                )

                                Text("This is the address of your self-hosted GameVault instance. Include http:// or https://")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let result = connectionResult {
                            VaultCard {
                                HStack(spacing: 10) {
                                    Image(systemName: connectionSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundStyle(connectionSuccess ? .green : .red)
                                    Text(result)
                                        .font(.subheadline)
                                        .foregroundStyle(connectionSuccess ? .green : .red)
                                }
                            }
                        }

                        VStack(spacing: 12) {
                            VaultButton(
                                title: isTestingConnection ? "Testing..." : "Test Connection",
                                icon: "wifi",
                                action: testConnection,
                                isLoading: isTestingConnection,
                                style: .ghost
                            )

                            VaultButton(
                                title: "Save & Continue",
                                icon: "checkmark",
                                action: save
                            )
                        }

                        VaultCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Common examples:")
                                    .font(.headline)
                                ForEach(examples, id: \.self) { example in
                                    Button {
                                        authVM.serverURL = example
                                    } label: {
                                        HStack {
                                            Image(systemName: "arrow.right.circle")
                                                .font(.caption)
                                                .foregroundStyle(.indigo)
                                            Text(example)
                                                .font(.caption)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Configure Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private let examples = [
        "http://192.168.1.100:3000",
        "http://10.0.0.5:3000",
        "https://games.yourdomain.com"
    ]

    private var backgroundGradient: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            Circle()
                .fill(theme.accentColor.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 44)
                .offset(x: -130, y: -260)

            Circle()
                .fill(Color.blue.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 140, y: -140)
        }
    }

    private func testConnection() {
        guard !authVM.serverURL.isEmpty else {
            connectionResult = "Please enter a server URL"
            connectionSuccess = false
            return
        }

        isTestingConnection = true
        connectionResult = nil
        APIService.shared.baseURL = authVM.serverURL

        Task {
            do {
                struct HealthResponse: Decodable { let status: String? }
                let _: HealthResponse = try await APIService.shared.request("/health", retryOnUnauthorized: false)
                connectionResult = "Connected successfully! Server is healthy."
                connectionSuccess = true
            } catch {
                connectionResult = "Could not connect: \(error.localizedDescription)"
                connectionSuccess = false
            }
            isTestingConnection = false
        }
    }

    private func save() {
        authVM.saveServerURL()
        dismiss()
    }
}
