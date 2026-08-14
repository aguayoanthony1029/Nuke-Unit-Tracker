import Foundation

protocol ScoreReviewProviding {
    func finalStatus(for eventID: String) async throws -> Bool?
}

/// ESPN supplies score context only. The user confirms every settlement.
struct ESPNScoreClient: ScoreReviewProviding {
    func finalStatus(for eventID: String) async throws -> Bool? {
        let url = URL(string: "https://site.api.espn.com/apis/site/v2/sports/scoreboard?limit=500")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ESPNScoreboard.self, from: data)
        return response.events.first(where: { $0.id == eventID })?.status.type.completed
    }
}

struct OddsAPIClient {
    let apiKey: String
    func sports() async throws -> [OddsAPISport] {
        var components = URLComponents(string: "https://api.the-odds-api.com/v4/sports")!
        components.queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([OddsAPISport].self, from: data)
    }
}

private struct ESPNScoreboard: Decodable {
    struct Event: Decodable { struct Status: Decodable { struct Type: Decodable { let completed: Bool }; let type: Type }; let id: String; let status: Status }
    let events: [Event]
}
struct OddsAPISport: Decodable, Identifiable { let key: String; let title: String; var id: String { key } }

