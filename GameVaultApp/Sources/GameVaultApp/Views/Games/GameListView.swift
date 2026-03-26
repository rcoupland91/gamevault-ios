import SwiftUI

struct GameLibraryView: View {
    @StateObject private var vm = GameListViewModel()
    @State private var selectedStatus: GameStatus? = nil
    @State private var showAddGame = false
    @State private var selectedGame: Game?

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status filter pills
                    statusFilterBar
                        .padding(.vertical, 8)

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search games...", text: $vm.searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: vm.searchText) { _, _ in
                                Task { await vm.loadGames(status: selectedStatus) }
                            }
                        if !vm.searchText.isEmpty {
                            Button { vm.searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // Content
                    if let error = vm.error {
                        ErrorBanner(message: error) { vm.error = nil }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    if vm.isLoading && vm.games.isEmpty {
                        Spacer()
                        ProgressView().tint(.indigo)
                        Spacer()
                    } else if vm.filteredGames.isEmpty {
                        emptyStateView
                    } else {
                        gameList
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddGame = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.indigo)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    sortMenu
                }
            }
            .sheet(isPresented: $showAddGame) {
                AddGameView {
                    Task { await vm.loadGames(status: selectedStatus) }
                }
            }
            .sheet(item: $selectedGame) { game in
                GameDetailView(game: game) {
                    Task { await vm.loadGames(status: selectedStatus) }
                }
            }
            .task { await vm.loadGames(status: selectedStatus) }
            .onChange(of: selectedStatus) { _, newStatus in
                Task { await vm.loadGames(status: newStatus) }
            }
        }
    }

    // MARK: - Status Filter

    private var statusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterPill(title: "All", icon: "square.grid.2x2", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                ForEach(GameStatus.allCases) { status in
                    FilterPill(title: status.displayName, icon: status.icon, isSelected: selectedStatus == status) {
                        selectedStatus = selectedStatus == status ? nil : status
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Game List

    private var gameList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(vm.filteredGames) { game in
                    GameRow(game: game)
                        .onTapGesture { selectedGame = game }
                        .contextMenu {
                            statusMenuItems(game: game)
                            Divider()
                            Button(role: .destructive) {
                                Task { await vm.deleteGame(id: game.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            promoteSwipeButton(game: game)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await vm.deleteGame(id: game.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 88)
        }
        .refreshable { await vm.loadGames(status: selectedStatus) }
    }

    @ViewBuilder
    private func promoteSwipeButton(game: Game) -> some View {
        switch game.status {
        case .toplay:
            Button {
                Task { await vm.updateGameStatus(game: game, newStatus: .playing) }
            } label: {
                Label("Playing", systemImage: "gamecontroller.fill")
            }
            .tint(.green)
        case .playing:
            Button {
                Task { await vm.updateGameStatus(game: game, newStatus: .played) }
            } label: {
                Label("Completed", systemImage: "checkmark.circle.fill")
            }
            .tint(.blue)
        case .played:
            EmptyView()
        }
    }

    @ViewBuilder
    private func statusMenuItems(game: Game) -> some View {
        ForEach(GameStatus.allCases) { status in
            if status != game.status {
                Button {
                    Task { await vm.updateGameStatus(game: game, newStatus: status) }
                } label: {
                    Label("Move to \(status.displayName)", systemImage: status.icon)
                }
            }
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach([
                ("updated_at", "Recently Updated"),
                ("title", "Title"),
                ("rating", "Rating"),
                ("hours", "Hours Played"),
                ("created_at", "Date Added")
            ], id: \.0) { key, label in
                Button {
                    if vm.sortBy == key {
                        vm.sortOrder = vm.sortOrder == "desc" ? "asc" : "desc"
                    } else {
                        vm.sortBy = key
                        vm.sortOrder = "desc"
                    }
                    Task { await vm.loadGames(status: selectedStatus) }
                } label: {
                    HStack {
                        Text(label)
                        if vm.sortBy == key {
                            Image(systemName: vm.sortOrder == "desc" ? "arrow.down" : "arrow.up")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(.indigo)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "gamecontroller")
                .font(.system(size: 70))
                .foregroundStyle(.quaternary)
            VStack(spacing: 8) {
                Text(vm.searchText.isEmpty ? "No Games" : "No Results")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(vm.searchText.isEmpty
                    ? "Add your first game to start building your library"
                    : "No games match \"\(vm.searchText)\"")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if vm.searchText.isEmpty {
                Button {
                    showAddGame = true
                } label: {
                    Label("Add Game", systemImage: "plus")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.indigo)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding()
    }

    private var backgroundGradient: some View {
        Color(uiColor: .systemBackground)
    }
}

// MARK: - Game Row

struct GameRow: View {
    let game: Game

    var body: some View {
        HStack(spacing: 14) {
            // Artwork thumbnail
            GameArtworkView(url: game.artUrl, cornerRadius: 10, aspectRatio: 1)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(game.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    StatusBadge(status: game.status)

                    if let rating = game.rating, rating > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text("\(rating)/5")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let hours = game.hours, hours > 0 {
                    Text(hours == hours.rounded() ? "\(Int(hours))h played" : String(format: "%.1fh played", hours))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                }
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.indigo)
                } else {
                    Capsule()
                        .fill(Color.primary.opacity(0.07))
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
