import Foundation

struct CommunityAPIConfiguration {
    static var baseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "COMMUNITY_API_URL") as? String,
              !raw.contains("example.com") else { return nil }
        return URL(string: raw)
    }
}

@MainActor
final class FreePicksViewModel: ObservableObject {
    @Published private(set) var picks: [FreePick] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        guard let baseURL = CommunityAPIConfiguration.baseURL else { return }
        isLoading = true; defer { isLoading = false }
        do {
            let url = baseURL.appending(path: "v1/free-picks")
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            picks = try decoder.decode(FreePicksResponse.self, from: data).items
        } catch { errorMessage = "Free Picks are unavailable right now." }
    }
}

private struct FreePicksResponse: Codable { let items: [FreePick] }

