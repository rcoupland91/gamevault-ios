import Foundation

// MARK: - Local Storage Service
// Stores games locally with optional iCloud key-value sync.
// iCloud sync requires the iCloud Key-Value capability in Xcode signing settings.

@Observable
final class LocalStorageService {
    static let shared = LocalStorageService()

    private(set) var games: [LocalGame] = []

    private let localKey  = "gv_local_games"
    private let iCloudKey = "gv_icloud_games"
    private let encoder   = JSONEncoder()
    private let decoder   = JSONDecoder()

    private init() {
        load()
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in self?.load() }
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    // MARK: - Persistence

    private func load() {
        // Prefer iCloud if available, fall back to local
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: iCloudKey),
           let decoded = try? decoder.decode([LocalGame].self, from: data) {
            games = decoded
        } else if let data = UserDefaults.standard.data(forKey: localKey),
                  let decoded = try? decoder.decode([LocalGame].self, from: data) {
            games = decoded
        }
    }

    private func save() {
        guard let data = try? encoder.encode(games) else { return }
        UserDefaults.standard.set(data, forKey: localKey)
        NSUbiquitousKeyValueStore.default.set(data, forKey: iCloudKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    // MARK: - CRUD

    func add(_ game: LocalGame) {
        games.insert(game, at: 0)
        save()
    }

    func update(_ game: LocalGame) {
        if let i = games.firstIndex(where: { $0.id == game.id }) {
            games[i] = game
            save()
        }
    }

    func delete(id: String) {
        games.removeAll { $0.id == id }
        save()
    }

    // MARK: - Filtered

    func games(for status: GameStatus) -> [LocalGame] {
        games.filter { $0.status == status }
    }

    // MARK: - Stats

    var stats: LocalStats {
        let played  = games.filter { $0.status == .played }
        let playing = games.filter { $0.status == .playing }
        let toplay  = games.filter { $0.status == .toplay }
        let hours   = games.compactMap(\.hoursPlayed).reduce(0, +)
        let ratings = games.compactMap(\.rating).filter { $0 > 0 }
        let avg     = ratings.isEmpty ? 0.0 : Double(ratings.reduce(0, +)) / Double(ratings.count)
        return LocalStats(
            total: games.count,
            playing: playing.count,
            played: played.count,
            toplay: toplay.count,
            totalHours: hours,
            avgRating: avg,
            recent: Array(games.prefix(6))
        )
    }
}

// MARK: - Local Game Model

struct LocalGame: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var status: GameStatus
    var rating: Int?
    var hoursPlayed: Double?
    var review: String?
    var notes: String?
    var platform: String?
    var genre: String?
    var year: String?
    var developer: String?
    var publisher: String?
    var artUrl: String?
    var metacritic: Int?
    var releaseDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        status: GameStatus = .toplay,
        rating: Int? = nil,
        hoursPlayed: Double? = nil,
        review: String? = nil,
        notes: String? = nil,
        platform: String? = nil,
        genre: String? = nil,
        year: String? = nil,
        developer: String? = nil,
        publisher: String? = nil,
        artUrl: String? = nil,
        metacritic: Int? = nil,
        releaseDate: Date? = nil
    ) {
        self.id          = id
        self.title       = title
        self.status      = status
        self.rating      = rating
        self.hoursPlayed = hoursPlayed
        self.review      = review
        self.notes       = notes
        self.platform    = platform
        self.genre       = genre
        self.year        = year
        self.developer   = developer
        self.publisher   = publisher
        self.artUrl      = artUrl
        self.metacritic  = metacritic
        self.releaseDate = releaseDate
        self.createdAt   = Date()
        self.updatedAt   = Date()
    }

    var displayRating: String {
        guard let r = rating, r > 0 else { return "Unrated" }
        return String(repeating: "★", count: r) + String(repeating: "☆", count: 5 - r)
    }

    var displayHours: String {
        guard let h = hoursPlayed, h > 0 else { return "" }
        return h == h.rounded() ? "\(Int(h))h" : String(format: "%.1fh", h)
    }

    mutating func touch() { updatedAt = Date() }
}

// MARK: - Local Stats

struct LocalStats {
    let total: Int
    let playing: Int
    let played: Int
    let toplay: Int
    let totalHours: Double
    let avgRating: Double
    let recent: [LocalGame]
}
