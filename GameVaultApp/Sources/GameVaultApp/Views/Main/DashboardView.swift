import SwiftUI

struct DashboardView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var vm = DashboardViewModel()
    @AppStorage("app_mode") private var appModeRaw = "server"
    @Environment(ThemeManager.self) private var theme
    @State private var showAddGame = false

    private var appMode: AppMode { AppMode(rawValue: appModeRaw) ?? .server }
    private var localStorage: LocalStorageService { .shared }

    var body: some View {
        NavigationStack {
            ZStack {
                dashboardBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        overviewHero

                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "At a Glance", subtitle: sectionSubtitle)
                            statsSection
                        }

                        if !currentlyPlaying.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Now Playing", subtitle: "\(currentlyPlaying.count) active")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(currentlyPlaying) { game in
                                            NavigationLink {
                                                GameDetailView(game: game)
                                            } label: {
                                                HeroGameCard(game: game)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.trailing, 20)
                                }
                            }
                        }

                        if !recentGames.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Recent Activity", subtitle: "Last added or updated")
                                VStack(spacing: 10) {
                                    ForEach(recentGames.prefix(5)) { game in
                                        NavigationLink {
                                            GameDetailView(game: game)
                                        } label: {
                                            GameRowCard(game: game)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        if currentlyPlaying.isEmpty && recentGames.isEmpty && !isLoading {
                            EmptyStateView(
                                icon: "gamecontroller",
                                title: "Your vault is empty",
                                subtitle: "Start tracking your games to see your stats and activity here.",
                                actionTitle: "Add Your First Game",
                                action: { showAddGame = true }
                            )
                            .frame(minHeight: 300)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddGame = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .refreshable {
                await loadData()
            }
        }
        .sheet(isPresented: $showAddGame) {
            AddGameView { Task { await loadData() } }
        }
        .task { await loadData() }
    }

    // MARK: - Stats Section

    @ViewBuilder
    private var statsSection: some View {
        let total    = statTotal
        let playing  = statPlaying
        let played   = statPlayed
        let toplay   = statToplay
        let hours    = statHours
        let avgRating = statAvgRating

        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Total Games", value: "\(total)", icon: "books.vertical.fill", color: .indigo)
                StatCard(title: "Playing", value: "\(playing)", icon: "gamecontroller.fill", color: .green)
                StatCard(title: "Completed", value: "\(played)", icon: "checkmark.circle.fill", color: .blue)
                StatCard(title: "Backlog", value: "\(toplay)", icon: "bookmark.fill", color: .orange)
            }

            if hours > 0 || avgRating > 0 {
                HStack(spacing: 12) {
                    if hours > 0 {
                        StatCard(
                            title: "Hours Logged",
                            value: hours < 100 ? String(format: "%.0f", hours) : "\(Int(hours))",
                            icon: "clock.fill",
                            color: .purple
                        )
                    }
                    if avgRating > 0 {
                        StatCard(
                            title: "Avg Rating",
                            value: String(format: "%.1f★", avgRating),
                            icon: "star.fill",
                            color: .yellow
                        )
                    }
                }
            }
        }
    }

    // MARK: - Data helpers

    private var isLoading: Bool {
        appMode == .server ? vm.isLoading : false
    }

    private var currentlyPlaying: [Game] {
        if appMode == .local {
            return localStorage.games.filter { $0.status == .playing }.map(localToGame)
        }
        return vm.stats?.recentActivity?.filter { $0.status == .playing } ?? []
    }

    private var recentGames: [Game] {
        if appMode == .local {
            return Array(localStorage.games.prefix(10)).map(localToGame)
        }
        return vm.stats?.recentActivity ?? []
    }

    private var statTotal: Int {
        appMode == .local ? localStorage.stats.total : (vm.stats?.total ?? 0)
    }
    private var statPlaying: Int {
        appMode == .local ? localStorage.stats.playing : (vm.stats?.playing ?? 0)
    }
    private var statPlayed: Int {
        appMode == .local ? localStorage.stats.played : (vm.stats?.played ?? 0)
    }
    private var statToplay: Int {
        appMode == .local ? localStorage.stats.toplay : (vm.stats?.toplay ?? 0)
    }
    private var statHours: Double {
        appMode == .local ? localStorage.stats.totalHours : (vm.stats?.totalHoursDouble ?? 0)
    }
    private var statAvgRating: Double {
        appMode == .local ? localStorage.stats.avgRating : (vm.stats?.avgRatingDouble ?? 0)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = authVM.currentUser?.username.capitalized ?? ""
        let timeGreeting: String
        switch hour {
        case 5..<12:  timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<22: timeGreeting = "Good evening"
        default:      timeGreeting = "Hello"
        }
        return name.isEmpty ? timeGreeting : "\(timeGreeting), \(name)"
    }

    private var heroSubtitle: String {
        if isLoading {
            return "Pulling your latest library activity."
        }
        if let game = currentlyPlaying.first {
            return "Pick up \(game.title) and keep your streak moving."
        }
        if statToplay > 0 {
            return "Your next session is already waiting in the backlog."
        }
        if statTotal > 0 {
            return "Your library is shaping up nicely. Keep the momentum going."
        }
        return "Track your games, reviews, and backlog in one polished place."
    }

    private var sectionSubtitle: String {
        if statTotal == 0 {
            return "Once you add games, your progress and habits will show up here."
        }
        return "A quick read on your collection, progress, and habits."
    }

    private var modeBadgeTitle: String {
        appMode == .local ? "App Only" : "Server Connected"
    }

    private var dashboardBackground: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            Circle()
                .fill(theme.meshColors[1].opacity(0.24))
                .frame(width: 280, height: 280)
                .blur(radius: 45)
                .offset(x: -130, y: -240)

            Circle()
                .fill(theme.meshColors[4].opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 140, y: -180)

            LinearGradient(
                colors: [
                    Color.clear,
                    Color(uiColor: .systemGroupedBackground).opacity(0.75),
                    Color(uiColor: .systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var overviewHero: some View {
        VaultCard(cornerRadius: 30, padding: 22) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(heroSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    dashboardBadge(title: modeBadgeTitle, icon: appMode == .local ? "iphone.gen3" : "dot.radiowaves.left.and.right")
                    dashboardBadge(title: "\(statTotal) tracked", icon: "books.vertical")
                }

                HStack(spacing: 12) {
                    heroMetric(title: "Playing", value: "\(statPlaying)", tint: .green)
                    heroMetric(title: "Completed", value: "\(statPlayed)", tint: .blue)
                    heroMetric(title: "Backlog", value: "\(statToplay)", tint: .orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(theme.accentColor.opacity(0.12))
                .frame(width: 120, height: 120)
                .blur(radius: 12)
                .offset(x: 36, y: -22)
        }
    }

    private func localToGame(_ local: LocalGame) -> Game {
        // Bridge LocalGame to Game for display
        let dict: [String: Any] = [
            "id": local.id,
            "title": local.title,
            "status": local.status.rawValue,
            "art_url": local.artUrl as Any,
            "platform": local.platform as Any,
            "rating": local.rating as Any,
            "hours": local.hoursPlayed as Any,
            "review": local.review as Any,
            "genre": local.genre as Any,
            "year": local.year as Any,
            "developer": local.developer as Any,
            "publisher": local.publisher as Any,
            "metacritic": local.metacritic as Any
        ].compactMapValues { $0 is NSNull ? nil : $0 }
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let game = try? JSONDecoder().decode(Game.self, from: data) else {
            // Return minimal shell if decode fails
            return Game.makeShell(id: local.id, title: local.title, status: local.status)
        }
        return game
    }

    private func loadData() async {
        guard appMode == .server else { return }
        await vm.load()
    }

    private func dashboardBadge(title: String, icon: String) -> some View {
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

    private func heroMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Game shell for local mode

extension Game {
    /// Creates a minimal Game from id/title/status for use in local-mode contexts.
    /// The JSON round-trip always succeeds for valid GameStatus values.
    static func makeShell(id: String, title: String, status: GameStatus) -> Game {
        let json = "{\"id\":\"\(id)\",\"title\":\"\(title.jsonEscaped)\",\"status\":\"\(status.rawValue)\"}"
        let data = json.data(using: .utf8)!
        return (try? JSONDecoder().decode(Game.self, from: data))!
    }
}

private extension String {
    var jsonEscaped: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
