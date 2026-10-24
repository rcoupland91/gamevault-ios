import Foundation
import SwiftUI

@MainActor
final class GameListViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""
    @Published var sortBy = "updated_at"
    @Published var sortOrder = "desc"

    private let service = GameService.shared
    private let localStorage = LocalStorageService.shared
    private var searchTask: Task<Void, Never>?
    private var currentStatus: GameStatus? = nil

    private var isLocalMode: Bool {
        AppMode(rawValue: UserDefaults.standard.string(forKey: "app_mode") ?? "server") == .local
    }

    var filteredGames: [Game] {
        if searchText.isEmpty { return games }
        return games.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Load

    func loadGames(status: GameStatus? = nil) async {
        currentStatus = status
        isLoading = true
        error = nil

        if isLocalMode {
            let localGames = status == nil ? localStorage.games : localStorage.games.filter { $0.status == status }
            let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
            let filtered = query.isEmpty ? localGames : localGames.filter { $0.title.lowercased().contains(query) }
            games = filtered.compactMap { localGameToGame($0) }
        } else {
            do {
                games = try await service.getGames(
                    status: status,
                    search: searchText.isEmpty ? nil : searchText,
                    sort: sortBy,
                    order: sortOrder
                )
            } catch {
                self.error = error.localizedDescription
            }
        }

        isLoading = false
    }

    // MARK: - Delete

    func deleteGame(id: String) async {
        if isLocalMode {
            localStorage.delete(id: id)
            games.removeAll { $0.id == id }
        } else {
            do {
                try await service.deleteGame(id: id)
                games.removeAll { $0.id == id }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Update Status

    func updateGameStatus(game: Game, newStatus: GameStatus) async {
        if isLocalMode {
            if let idx = localStorage.games.firstIndex(where: { $0.id == game.id }) {
                var updated = localStorage.games[idx]
                updated.status = newStatus
                updated.touch()
                localStorage.update(updated)
            }
            await loadGames(status: currentStatus)
        } else {
            var request = GameRequest(from: game)
            request.status = newStatus.rawValue
            do {
                let updated = try await service.updateGame(id: game.id, request)
                if let index = games.firstIndex(where: { $0.id == game.id }) {
                    games[index] = updated
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Local helper

    private func localGameToGame(_ local: LocalGame) -> Game? {
        var dict: [String: Any] = ["id": local.id, "title": local.title, "status": local.status.rawValue]
        if let v = local.rating      { dict["rating"]    = v }
        if let v = local.hoursPlayed { dict["hours"]     = v }
        if let v = local.review      { dict["review"]    = v }
        if let v = local.notes       { dict["notes"]     = v }
        if let v = local.platform    { dict["platform"]  = v }
        if let v = local.genre       { dict["genre"]     = v }
        if let v = local.year        { dict["year"]      = v }
        if let v = local.developer   { dict["developer"] = v }
        if let v = local.publisher   { dict["publisher"] = v }
        if let v = local.artUrl      { dict["art_url"]   = v }
        if let v = local.metacritic  { dict["metacritic"] = v }
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(Game.self, from: data)
    }
}

// MARK: - GameDetailViewModel

@MainActor
final class GameDetailViewModel: ObservableObject {
    @Published var game: Game
    @Published var isSaving = false
    @Published var isDeleting = false
    @Published var error: String?
    @Published var saveSuccess = false
    @Published var availablePlatforms: [String] = GameDetailViewModel.allPlatforms

    @Published var title: String
    @Published var status: GameStatus
    @Published var rating: Int
    @Published var hours: String
    @Published var platform: String
    @Published var genre: String
    @Published var year: String
    @Published var review: String
    @Published var notes: String
    @Published var developer: String
    @Published var publisher: String

    private let service = GameService.shared
    private var isLocalMode: Bool {
        AppMode(rawValue: UserDefaults.standard.string(forKey: "app_mode") ?? "server") == .local
    }

    init(game: Game) {
        self.game = game
        self.title = game.title
        self.status = game.status
        self.rating = game.rating ?? 0
        self.hours = game.hours.map { String(format: $0 == $0.rounded() ? "%.0f" : "%.1f", $0) } ?? ""
        self.platform = game.platform ?? ""
        self.genre = game.genre ?? ""
        self.year = game.year ?? ""
        self.review = game.review ?? ""
        self.notes = game.notes ?? ""
        self.developer = game.developer ?? ""
        self.publisher = game.publisher ?? ""
    }

    static let allPlatforms: [String] = [
        "PC", "PlayStation 5", "PlayStation 4", "PlayStation 3",
        "Xbox Series X/S", "Xbox One", "Xbox 360",
        "Nintendo Switch", "Nintendo Switch 2",
        "iOS", "Android", "macOS", "Linux"
    ]

    func save() async {
        isSaving = true
        error = nil

        if isLocalMode {
            let ls = LocalStorageService.shared
            if let idx = ls.games.firstIndex(where: { $0.id == game.id }) {
                var local = ls.games[idx]
                local.title     = title
                local.status    = status
                local.rating    = rating > 0 ? rating : nil
                local.hoursPlayed = Double(hours)
                local.review    = review.isEmpty   ? nil : review
                local.notes     = notes.isEmpty    ? nil : notes
                local.platform  = platform.isEmpty ? nil : platform
                local.genre     = genre.isEmpty    ? nil : genre
                local.year      = year.isEmpty     ? nil : year
                local.developer = developer.isEmpty ? nil : developer
                local.publisher = publisher.isEmpty ? nil : publisher
                local.touch()
                ls.update(local)
                saveSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.saveSuccess = false }
            } else {
                error = "Game not found in local library."
            }
        } else {
            var request = GameRequest(from: game)
            request.title     = title
            request.status    = status.rawValue
            request.rating    = rating > 0 ? rating : nil
            request.hours     = Double(hours)
            request.platform  = platform.isEmpty ? nil : platform
            request.genre     = genre.isEmpty    ? nil : genre
            request.year      = year.isEmpty     ? nil : year
            request.review    = review.isEmpty   ? nil : review
            request.notes     = notes.isEmpty    ? nil : notes
            request.developer = developer.isEmpty ? nil : developer
            request.publisher = publisher.isEmpty ? nil : publisher
            do {
                game = try await service.updateGame(id: game.id, request)
                saveSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.saveSuccess = false }
            } catch {
                self.error = error.localizedDescription
            }
        }

        isSaving = false
    }

    func delete() async -> Bool {
        isDeleting = true
        error = nil
        defer { isDeleting = false }

        if isLocalMode {
            LocalStorageService.shared.delete(id: game.id)
            return true
        }

        do {
            try await service.deleteGame(id: game.id)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}

// MARK: - AddGameViewModel

@MainActor
final class AddGameViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [RAWGGame] = []
    @Published var isSearching = false
    @Published var isAdding = false
    @Published var error: String?
    @Published var addedGame: Game?

    @Published var manualTitle = ""
    @Published var selectedStatus = GameStatus.toplay
    @Published var selectedRating = 0
    @Published var hours = ""
    @Published var platform = ""
    @Published var genre = ""
    @Published var year = ""
    @Published var notes = ""

    private let service = GameService.shared
    private let localStorage = LocalStorageService.shared
    private let rawgDirect = RAWGDirectService.shared
    private var searchTask: Task<Void, Never>?

    private var isLocalMode: Bool {
        AppMode(rawValue: UserDefaults.standard.string(forKey: "app_mode") ?? "server") == .local
    }

    func search() async {
        guard !searchText.isEmpty else { searchResults = []; return }

        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            isSearching = true
            do {
                if isLocalMode {
                    searchResults = try await rawgDirect.search(query: searchText)
                } else {
                    let response = try await service.searchRAWG(query: searchText)
                    searchResults = response.results
                }
            } catch {
                if !Task.isCancelled { self.error = error.localizedDescription }
            }
            isSearching = false
        }
    }

    func addGame(from rawgGame: RAWGGame, platform: String? = nil) async {
        isAdding = true
        error = nil

        if isLocalMode {
            let local = LocalGame(
                title: rawgGame.title ?? "Unknown",
                status: selectedStatus,
                platform: platform ?? rawgGame.platforms?.first,
                genre: rawgGame.genres?.first,
                year: rawgGame.year,
                artUrl: rawgGame.artUrl,
                metacritic: rawgGame.metacritic
            )
            localStorage.add(local)
            addedGame = Game.makeShell(id: local.id, title: local.title, status: local.status)
        } else {
            let request = GameRequest(
                rawgId: rawgGame.rawgId,
                title: rawgGame.title ?? "Unknown",
                status: selectedStatus.rawValue,
                rating: nil, hours: nil, review: nil,
                platform: platform ?? rawgGame.platforms?.first,
                genre: rawgGame.genres?.first,
                year: rawgGame.year,
                artUrl: rawgGame.artUrl,
                backgroundUrl: nil, developer: nil, publisher: nil,
                metacritic: rawgGame.metacritic,
                rawgSlug: rawgGame.rawgSlug,
                notes: nil
            )
            do { addedGame = try await service.createGame(request) }
            catch { self.error = error.localizedDescription }
        }

        isAdding = false
    }

    func addManualGame() async {
        guard !manualTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter a game title"
            return
        }

        isAdding = true
        error = nil

        if isLocalMode {
            let local = LocalGame(
                title: manualTitle,
                status: selectedStatus,
                rating: selectedRating > 0 ? selectedRating : nil,
                hoursPlayed: Double(hours),
                notes: notes.isEmpty ? nil : notes,
                platform: platform.isEmpty ? nil : platform,
                genre: genre.isEmpty ? nil : genre,
                year: year.isEmpty ? nil : year
            )
            localStorage.add(local)
            addedGame = Game.makeShell(id: local.id, title: local.title, status: local.status)
        } else {
            let request = GameRequest(
                rawgId: nil,
                title: manualTitle,
                status: selectedStatus.rawValue,
                rating: selectedRating > 0 ? selectedRating : nil,
                hours: Double(hours),
                review: nil,
                platform: platform.isEmpty ? nil : platform,
                genre: genre.isEmpty ? nil : genre,
                year: year.isEmpty ? nil : year,
                artUrl: nil, backgroundUrl: nil, developer: nil, publisher: nil,
                metacritic: nil, rawgSlug: nil,
                notes: notes.isEmpty ? nil : notes
            )
            do { addedGame = try await service.createGame(request) }
            catch { self.error = error.localizedDescription }
        }

        isAdding = false
    }
}

// MARK: - GameRequest init helper

extension GameRequest {
    init(
        rawgId: Int?, title: String, status: String,
        rating: Int?, hours: Double?, review: String?,
        platform: String?, genre: String?, year: String?,
        artUrl: String?, backgroundUrl: String?,
        developer: String?, publisher: String?,
        metacritic: Int?, rawgSlug: String?, notes: String?
    ) {
        self.rawgId = rawgId; self.title = title; self.status = status
        self.rating = rating; self.hours = hours; self.review = review
        self.platform = platform; self.genre = genre; self.year = year
        self.artUrl = artUrl; self.backgroundUrl = backgroundUrl
        self.developer = developer; self.publisher = publisher
        self.metacritic = metacritic; self.rawgSlug = rawgSlug; self.notes = notes
    }
}
