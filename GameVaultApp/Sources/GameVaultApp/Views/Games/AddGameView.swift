import SwiftUI

struct AddGameView: View {
    @StateObject private var vm = AddGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme
    var onAdded: (() -> Void)?

    @State private var mode: AddMode = .search
    @State private var platformPickerGame: RAWGGame?

    enum AddMode: String, CaseIterable {
        case search = "Search RAWG"
        case manual = "Manual Entry"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                addGameBackground
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    VaultCard(cornerRadius: 28, padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Build your library")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                            Text(mode == .search
                                 ? "Search RAWG for artwork and metadata, then drop games straight into your vault."
                                 : "Prefer to keep it simple? Add a game yourself and fill in the details later.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Picker("Mode", selection: $mode) {
                                ForEach(AddMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    if mode == .search { searchView } else { manualView }
                }
            }
            .navigationTitle("Add Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: vm.addedGame) { _, game in
                if game != nil { onAdded?(); dismiss() }
            }
        }
    }

    // MARK: - Search

    private var searchView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search for a game…", text: $vm.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: vm.searchText) { _, _ in Task { await vm.search() } }
                if !vm.searchText.isEmpty {
                    Button { vm.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GameStatus.allCases) { s in
                        FilterPill(title: s.displayName, icon: s.icon, isSelected: vm.selectedStatus == s) {
                            vm.selectedStatus = s
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)

            if let error = vm.error {
                ErrorBanner(message: error) { vm.error = nil }.padding(.horizontal, 16).padding(.bottom, 8)
            }

            if vm.isSearching {
                Spacer()
                ProgressView("Searching…").tint(theme.accentColor)
                Spacer()
            } else if vm.searchResults.isEmpty && !vm.searchText.isEmpty {
                Spacer()
                EmptyStateView(icon: "magnifyingglass", title: "No results", subtitle: "Try a different term or add manually.")
                Spacer()
            } else if vm.searchResults.isEmpty {
                Spacer()
                EmptyStateView(icon: "magnifyingglass.circle", title: "Search for a game", subtitle: "Powered by the RAWG database.")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.searchResults) { game in
                            RAWGGameRow(game: game, isAdding: vm.isAdding) {
                                let platforms = game.platforms ?? []
                                if platforms.count > 1 { platformPickerGame = game }
                                else { Task { await vm.addGame(from: game, platform: platforms.first) } }
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 80)
                }
                .confirmationDialog("Which platform?", isPresented: Binding(
                    get: { platformPickerGame != nil },
                    set: { if !$0 { platformPickerGame = nil } }
                ), titleVisibility: .visible) {
                    if let game = platformPickerGame {
                        ForEach(game.platforms ?? [], id: \.self) { p in
                            Button(p) {
                                Task { await vm.addGame(from: game, platform: p) }
                                platformPickerGame = nil
                            }
                        }
                        Button("Cancel", role: .cancel) { platformPickerGame = nil }
                    }
                }
            }
        }
    }

    // MARK: - Manual

    private var manualView: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultCard(cornerRadius: 24) {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title *").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                            VaultTextField(placeholder: "Game title", text: $vm.manualTitle, icon: "gamecontroller")
                        }
                        Divider().opacity(0.5)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: GameStatus.allCases.count), spacing: 8) {
                                ForEach(GameStatus.allCases) { s in
                                    StatusSelectButton(status: s, isSelected: vm.selectedStatus == s) { vm.selectedStatus = s }
                                }
                            }
                        }
                        Divider().opacity(0.5)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Platform").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                            VaultTextField(placeholder: "e.g. PlayStation 5", text: $vm.platform, icon: "display")
                        }
                        Divider().opacity(0.5)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Genre").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                            VaultTextField(placeholder: "e.g. Action RPG", text: $vm.genre, icon: "tag")
                        }
                        Divider().opacity(0.5)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Year").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                            VaultTextField(placeholder: "e.g. 2024", text: $vm.year, icon: "calendar", keyboardType: .numberPad, autocapitalization: .never, autocorrect: false)
                        }
                        Divider().opacity(0.5)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hours Played").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                            VaultTextField(placeholder: "e.g. 25", text: $vm.hours, icon: "clock", keyboardType: .decimalPad, autocapitalization: .never, autocorrect: false)
                        }
                        Divider().opacity(0.5)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rating").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                            StarRatingView(rating: $vm.selectedRating)
                        }
                    }
                }

                if let error = vm.error {
                    ErrorBanner(message: error) { vm.error = nil }
                }

                VaultButton(title: "Add to Library", icon: "plus.circle", action: {
                    Task { await vm.addManualGame() }
                }, isLoading: vm.isAdding)
            }
            .padding(.horizontal, 16).padding(.bottom, 80)
        }
    }
}

// MARK: - RAWG Game Row

struct RAWGGameRow: View {
    let game: RAWGGame
    let isAdding: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            GameArtworkView(url: game.artUrl, cornerRadius: 10, aspectRatio: 1)
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(game.title ?? "Unknown")
                    .font(.subheadline).fontWeight(.semibold).lineLimit(2)
                HStack(spacing: 8) {
                    if let year = game.year {
                        Text(year).font(.caption).foregroundStyle(.secondary)
                    }
                    if let mc = game.metacritic {
                        Text("MC \(mc)")
                            .font(.caption2).fontWeight(.semibold).foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(mc >= 75 ? Color.green : (mc >= 50 ? Color.yellow : Color.red))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                if let genres = game.genres, !genres.isEmpty {
                    Text(genres.prefix(2).joined(separator: ", "))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }

            Spacer()

            Button(action: onAdd) {
                if isAdding { ProgressView().scaleEffect(0.85) }
                else { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Color.accentColor) }
            }
            .disabled(isAdding)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}

private extension AddGameView {
    var addGameBackground: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            Circle()
                .fill(theme.accentColor.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 44)
                .offset(x: -140, y: -250)

            Circle()
                .fill(Color.orange.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 150, y: -130)
        }
    }
}
