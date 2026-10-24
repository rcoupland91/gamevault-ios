import Foundation

// MARK: - Direct RAWG API service (no GameVault server required)
// Users can get a free API key at: https://rawg.io/apidocs

enum RAWGDirectError: LocalizedError {
    case noApiKey
    case unauthorized
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "No RAWG API key set. Get your free key at rawg.io/apidocs and add it in Profile → Settings."
        case .unauthorized:
            return "Invalid RAWG API key. Check your key in Profile → Settings."
        case .networkError(let e):
            return "Search failed: \(e.localizedDescription)"
        }
    }
}

final class RAWGDirectService {
    static let shared = RAWGDirectService()
    private init() {}

    private let baseURL = "https://api.rawg.io/api"

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "rawg_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "rawg_api_key") }
    }

    var hasApiKey: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    func search(query: String, page: Int = 1) async throws -> [RAWGGame] {
        guard hasApiKey else { throw RAWGDirectError.noApiKey }

        var comps = URLComponents(string: "\(baseURL)/games")!
        comps.queryItems = [
            .init(name: "search", value: query),
            .init(name: "page", value: "\(page)"),
            .init(name: "page_size", value: "20"),
            .init(name: "key", value: apiKey.trimmingCharacters(in: .whitespaces)),
        ]

        guard let url = comps.url else { throw URLError(.badURL) }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw RAWGDirectError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw RAWGDirectError.unauthorized
        }

        let decoded = try JSONDecoder().decode(RawgListResponse.self, from: data)
        return decoded.results.map { $0.toRAWGGame() }
    }

    // MARK: - Native RAWG response types

    private struct RawgListResponse: Decodable {
        let count: Int
        let results: [RawgItem]
    }

    private struct RawgItem: Decodable {
        let id: Int
        let slug: String
        let name: String
        let backgroundImage: String?
        let released: String?
        let platforms: [RawgPlatformWrapper]?
        let genres: [RawgGenre]?
        let metacritic: Int?
        let rating: Double?

        enum CodingKeys: String, CodingKey {
            case id, slug, name, metacritic, rating
            case backgroundImage = "background_image"
            case released, platforms, genres
        }

        func toRAWGGame() -> RAWGGame {
            RAWGGame(
                rawgId: id,
                rawgSlug: slug,
                title: name,
                artUrl: backgroundImage,
                year: released.flatMap { String($0.prefix(4)) },
                platforms: platforms?.map { $0.platform.name },
                genres: genres?.map { $0.name },
                metacritic: metacritic,
                rating: rating
            )
        }
    }

    private struct RawgPlatformWrapper: Decodable {
        let platform: RawgPlatform
        struct RawgPlatform: Decodable { let name: String }
    }

    private struct RawgGenre: Decodable { let name: String }
}
