import SwiftUI

// MARK: - Now Playing

struct NowPlayingView: View {
    @StateObject private var vm = GameListViewModel()
    @State private var showAddGame = false

    var body: some View {
        NavigationStack {
            GameStatusListView(vm: vm, status: .playing, showAddGame: $showAddGame)
                .navigationTitle("Now Playing")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { addButton }
                }
                .sheet(isPresented: $showAddGame) {
                    AddGameView { Task { await vm.loadGames(status: .playing) } }
                }
                .task { await vm.loadGames(status: .playing) }
        }
    }

    private var addButton: some View {
        Button { showAddGame = true } label: {
            Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Color.accentColor)
        }
    }
}

// MARK: - Library (Completed)

struct GameLibraryView: View {
    @StateObject private var vm = GameListViewModel()
    @State private var showAddGame = false

    var body: some View {
        NavigationStack {
            GameStatusListView(vm: vm, status: .played, showAddGame: $showAddGame)
                .navigationTitle("Completed")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { addButton }
                }
                .sheet(isPresented: $showAddGame) {
                    AddGameView { Task { await vm.loadGames(status: .played) } }
                }
                .task { await vm.loadGames(status: .played) }
        }
    }

    private var addButton: some View {
        Button { showAddGame = true } label: {
            Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Color.accentColor)
        }
    }
}

// MARK: - Backlog

struct BacklogView: View {
    @StateObject private var vm = GameListViewModel()
    @State private var showAddGame = false

    var body: some View {
        NavigationStack {
            GameStatusListView(vm: vm, status: .toplay, showAddGame: $showAddGame)
                .navigationTitle("Backlog")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { addButton }
                }
                .sheet(isPresented: $showAddGame) {
                    AddGameView { Task { await vm.loadGames(status: .toplay) } }
                }
                .task { await vm.loadGames(status: .toplay) }
        }
    }

    private var addButton: some View {
        Button { showAddGame = true } label: {
            Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Color.accentColor)
        }
    }
}

// MARK: - Shared Status List View

private struct GameStatusListView: View {
    @ObservedObject var vm: GameListViewModel
    let status: GameStatus
    @Binding var showAddGame: Bool
    @Environment(ThemeManager.self) private var theme
    @State private var selectedGame: Game?

    private var displayedGames: [Game] {
        vm.filteredGames
    }

    var body: some View {
        ZStack {
            listBackground
                .ignoresSafeArea()

            Group {
                if vm.isLoading && displayedGames.isEmpty {
                    loadingState
                } else if displayedGames.isEmpty {
                    emptyState
                } else {
                    gameList
                }
            }
        }
        .searchable(text: $vm.searchText, prompt: "Search games…")
        .onChange(of: vm.searchText) { _, _ in
            Task { await vm.loadGames(status: status) }
        }
        .navigationDestination(item: $selectedGame) { game in
            GameDetailView(game: game, onSave: {
                Task { await vm.loadGames(status: status) }
            })
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            summaryCard
                .redacted(reason: .placeholder)

            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 88)
                    .redacted(reason: .placeholder)
                    .shimmering()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            summaryCard

            EmptyStateView(
                icon: status.icon,
                title: emptyTitle,
                subtitle: emptySubtitle,
                actionTitle: "Add Game",
                action: { showAddGame = true }
            )
        }
        .padding(.horizontal, 20)
    }

    private var gameList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 14) {
                summaryCard

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        sortPill("Recent", key: "updated_at")
                        sortPill("Title", key: "title")
                        sortPill("Rating", key: "rating")
                        sortPill("Hours", key: "hours")
                    }
                }

                ForEach(displayedGames) { game in
                    SwipeableGameRow(
                        action: primarySwipeConfig(for: game),
                        onTap: { selectedGame = game }
                    ) {
                        GameRowCard(game: game)
                    }
                    .contextMenu {
                        gameContextMenu(game)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .refreshable {
            await vm.loadGames(status: status)
        }
    }

    private func sortPill(_ label: String, key: String) -> some View {
        FilterPill(title: label, isSelected: vm.sortBy == key) {
            vm.sortBy = key
            Task { await vm.loadGames(status: status) }
        }
    }

    @ViewBuilder
    private func gameContextMenu(_ game: Game) -> some View {
        Menu("Move to…") {
            ForEach(GameStatus.allCases.filter { $0 != game.status }) { s in
                Button {
                    Task { await vm.updateGameStatus(game: game, newStatus: s) }
                } label: {
                    Label(s.displayName, systemImage: s.icon)
                }
            }
        }
        Divider()
        Button(role: .destructive) {
            Task { await vm.deleteGame(id: game.id) }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func primarySwipeConfig(for game: Game) -> SwipeActionConfig? {
        switch game.status {
        case .toplay:
            return SwipeActionConfig(
                title: "Move to Playing",
                systemImage: "gamecontroller.fill",
                tint: .green
            ) {
                Task { await vm.updateGameStatus(game: game, newStatus: .playing) }
            }
        case .playing:
            return SwipeActionConfig(
                title: "Mark Completed",
                systemImage: "checkmark.circle.fill",
                tint: .blue
            ) {
                Task { await vm.updateGameStatus(game: game, newStatus: .played) }
            }
        case .played:
            return nil
        }
    }

    private var emptyTitle: String {
        switch status {
        case .playing: return "Nothing playing yet"
        case .played:  return "No completed games"
        case .toplay:  return "Backlog is clear"
        }
    }

    private var emptySubtitle: String {
        switch status {
        case .playing: return "Add the game you're currently playing to track your progress."
        case .played:  return "Mark games as completed to build your history."
        case .toplay:  return "Add games you want to play to build your backlog."
        }
    }

    private var countLabel: String {
        let count = displayedGames.count
        if count == 1 { return "1 game" }
        return "\(count) games"
    }

    private var statusSummary: String {
        switch status {
        case .playing: return "Keep your current obsession front and center."
        case .played: return "Your finished games, reviews, and personal history live here."
        case .toplay: return "A shortlist of what to dive into next."
        }
    }

    private var statusTint: Color {
        switch status {
        case .playing: return .green
        case .played: return .blue
        case .toplay: return .orange
        }
    }

    private var summaryCard: some View {
        VaultCard(cornerRadius: 26, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(status.displayName)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                        Text(statusSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Image(systemName: status.icon)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(statusTint)
                        .frame(width: 44, height: 44)
                        .background(statusTint.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                HStack(spacing: 8) {
                    InfoChip(text: countLabel, icon: "books.vertical")
                    InfoChip(text: vm.sortBy.replacingOccurrences(of: "_", with: " ").capitalized, icon: "arrow.up.arrow.down")
                }
            }
        }
    }

    private var listBackground: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            Circle()
                .fill(statusTint.opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 45)
                .offset(x: -140, y: -260)

            Circle()
                .fill(theme.accentColor.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 150, y: -170)
        }
    }
}

private struct SwipeActionConfig {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void
}

private struct SwipeableGameRow<Content: View>: View {
    let action: SwipeActionConfig?
    let onTap: () -> Void
    let content: Content

    @State private var dragOffset: CGFloat = 0
    @State private var isTriggering = false

    private let revealWidth: CGFloat = 118
    private let triggerThreshold: CGFloat = 84

    init(
        action: SwipeActionConfig?,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if let action {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(action.tint.opacity(0.18))

                HStack(spacing: 10) {
                    Image(systemName: action.systemImage)
                        .font(.headline.weight(.bold))
                    Text(action.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(action.tint)
                .padding(.leading, 18)
                .opacity(min(max(dragOffset / revealWidth, 0.15), 1))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onTap) {
                content
            }
            .buttonStyle(.plain)
            .offset(x: dragOffset)
            .gesture(dragGesture)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: dragOffset)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { value in
                guard action != nil, !isTriggering else { return }
                dragOffset = max(0, min(value.translation.width, revealWidth))
            }
            .onEnded { value in
                guard let action, !isTriggering else {
                    dragOffset = 0
                    return
                }

                let dragWidth = max(value.translation.width, value.predictedEndTranslation.width)
                let shouldTrigger = dragWidth > triggerThreshold

                if shouldTrigger {
                    isTriggering = true
                    dragOffset = revealWidth
                    action.action()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        dragOffset = 0
                        isTriggering = false
                    }
                } else {
                    dragOffset = 0
                }
            }
    }
}

// MARK: - Shimmer

private extension View {
    func shimmering() -> some View {
        self.overlay(
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.3), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: -200)
        )
    }
}
