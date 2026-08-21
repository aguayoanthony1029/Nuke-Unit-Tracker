import Foundation

/// The app only uses this public base URL. Discord credentials, premium rules,
/// and publisher access stay on the Nuke service and never ship in iOS.
struct CommunityAPIConfiguration {
    static var baseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "COMMUNITY_API_URL") as? String,
              !raw.isEmpty,
              !raw.contains("example.com") else { return nil }
        return URL(string: raw)
    }
}

/// Paid/VIP content remains intentionally off in the default store build.
/// Turning it on is a deliberate release configuration step after the
/// platform-compliant entitlement product and Discord service are ready.
enum NukeFeatureFlags {
    static var vaultVerificationEnabled: Bool {
        let raw = Bundle.main.object(forInfoDictionaryKey: "VAULT_VERIFICATION_ENABLED") as? String
        return ["1", "true", "yes"].contains(raw?.lowercased())
    }
}

struct NukeContentPage: Codable {
    let items: [NukeEditorialPost]
    let nextCursor: String?
}

enum NukeContentServiceError: LocalizedError {
    case unavailable
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unavailable: "The Nuke content service has not been configured yet."
        case .invalidResponse: "The Nuke content service returned an unexpected response."
        }
    }
}

enum NukeContentService {
    static func fetchContent(
        visibility: EditorialVisibility,
        accessToken: String? = nil,
        cursor: String? = nil,
        limit: Int = 20
    ) async throws -> NukeContentPage {
        guard let baseURL = CommunityAPIConfiguration.baseURL else {
            throw NukeContentServiceError.unavailable
        }

        var components = URLComponents(url: baseURL.appending(path: "v1/content/\(visibility.rawValue)"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            cursor.map { URLQueryItem(name: "before", value: $0) }
        ].compactMap { $0 }
        guard let url = components?.url else { throw NukeContentServiceError.invalidResponse }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NukeContentServiceError.invalidResponse
        }
        return try NukeJSON.makeDecoder().decode(NukeContentPage.self, from: data)
    }

    static func fetchTailBoardPicks(
        visibility: EditorialVisibility,
        accessToken: String? = nil
    ) async throws -> [NukePick] {
        guard let baseURL = CommunityAPIConfiguration.baseURL else {
            throw NukeContentServiceError.unavailable
        }

        var components = URLComponents(url: baseURL.appending(path: "v1/picks/tail-board"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "visibility", value: visibility.rawValue)]
        guard let url = components?.url else { throw NukeContentServiceError.invalidResponse }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NukeContentServiceError.invalidResponse
        }
        return try NukeJSON.makeDecoder().decode(TailBoardPickResponse.self, from: data).items
    }

    /// Retains compatibility with the original Discord relay while the richer
    /// editorial endpoint is being rolled out.
    static func fetchLegacyFreePicks() async throws -> [NukeEditorialPost] {
        guard let baseURL = CommunityAPIConfiguration.baseURL else {
            throw NukeContentServiceError.unavailable
        }
        let url = baseURL.appending(path: "v1/free-picks")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NukeContentServiceError.invalidResponse
        }
        let responseBody = try NukeJSON.makeDecoder().decode(LegacyFreePicksResponse.self, from: data)
        return responseBody.items.map { oldPick in
            NukeEditorialPost(
                id: oldPick.id,
                visibility: .free,
                kind: .pickCard,
                title: "Nuke Free Pick",
                summary: oldPick.content,
                body: oldPick.content,
                imageURLs: oldPick.imageURLs,
                tags: ["Free"],
                publishedAt: oldPick.postedAt,
                updatedAt: oldPick.editedAt
            )
        }
    }
}

@MainActor
final class NukeContentFeedViewModel: ObservableObject {
    @Published private(set) var posts: [NukeEditorialPost] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isShowingLocalBriefing = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    let visibility: EditorialVisibility
    private var nextCursor: String?

    init(visibility: EditorialVisibility) {
        self.visibility = visibility
    }

    func load(accessToken: String? = nil) async {
        isLoading = true
        defer { isLoading = false }
        nextCursor = nil
        errorMessage = nil

        guard CommunityAPIConfiguration.baseURL != nil else {
            posts = visibility == .free ? NukeLocalContent.freeBriefings : []
            isShowingLocalBriefing = visibility == .free
            hasMore = false
            return
        }

        do {
            let page = try await NukeContentService.fetchContent(visibility: visibility, accessToken: accessToken)
            posts = page.items
            nextCursor = page.nextCursor
            hasMore = page.nextCursor != nil
            isShowingLocalBriefing = false
        } catch {
            if visibility == .free, let legacy = try? await NukeContentService.fetchLegacyFreePicks(), !legacy.isEmpty {
                posts = legacy
                isShowingLocalBriefing = false
                errorMessage = "Showing the original feed while the command feed reconnects."
            } else {
                posts = visibility == .free ? NukeLocalContent.freeBriefings : []
                isShowingLocalBriefing = visibility == .free
                errorMessage = visibility == .free
                    ? "Live Nuke content is reconnecting. Your tracker is still fully available."
                    : "The Vault could not be reached right now."
            }
            hasMore = false
        }
    }

    func loadMore(accessToken: String? = nil) async {
        guard let nextCursor, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await NukeContentService.fetchContent(
                visibility: visibility,
                accessToken: accessToken,
                cursor: nextCursor
            )
            posts.append(contentsOf: page.items.filter { newPost in !posts.contains(where: { $0.id == newPost.id }) })
            self.nextCursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            errorMessage = "More Nuke content could not be loaded right now."
        }
    }
}

@MainActor
final class TailBoardRadarViewModel: ObservableObject {
    @Published private(set) var picks: [NukePick] = []
    @Published private(set) var isLoading = false

    func load(visibility: EditorialVisibility = .free, accessToken: String? = nil) async {
        guard CommunityAPIConfiguration.baseURL != nil else { return }
        isLoading = true
        defer { isLoading = false }
        picks = (try? await NukeContentService.fetchTailBoardPicks(visibility: visibility, accessToken: accessToken)) ?? []
    }
}

private struct TailBoardPickResponse: Codable { let items: [NukePick] }
private struct LegacyFreePicksResponse: Codable { let items: [FreePick] }

enum NukeJSON {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: value) ?? ISO8601DateFormatter.standard.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected an ISO-8601 date.")
        }
        return decoder
    }
}

private extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

/// Offline copy is deliberately timeless: it gives a new user useful context
/// without inventing current games, lines, results, or betting claims.
enum NukeLocalContent {
    static let freeBriefings: [NukeEditorialPost] = [
        NukeEditorialPost(
            id: "field-manual-bankroll",
            slug: "field-manual-bankroll",
            visibility: .free,
            kind: .brief,
            title: "Nuke Field Manual: protect the bankroll",
            summary: "The tracker is live. Start with a unit size you can comfortably absorb, then let your record tell the story.",
            body: "Nuke Unit Tracker is built for clean records, not pressure. Log the stake, line, and result. Use the dashboard to review performance before changing your process.",
            tags: ["Free", "Tracker", "Bankroll"],
            publishedAt: .now
        ),
        NukeEditorialPost(
            id: "field-manual-tail-board",
            slug: "field-manual-tail-board",
            visibility: .free,
            kind: .analysis,
            title: "Tail Board is standing by",
            summary: "When Nuke publishes a selection, save it to your private board, choose singles or a parlay, then copy the details to review on your own.",
            body: "The Tail Board never opens a sportsbook, fills a wager, or places a bet. It is a clean workspace for comparing selections and keeping your own notes.",
            tags: ["Free", "Tail Board"],
            publishedAt: .now.addingTimeInterval(-60 * 60)
        ),
        NukeEditorialPost(
            id: "field-manual-responsible",
            slug: "field-manual-responsible",
            visibility: .free,
            kind: .announcement,
            title: "The mission is discipline",
            summary: "Set limits, take breaks, and never chase a result. This app records your decisions; it cannot guarantee an outcome.",
            body: "If betting stops being fun, step away and use a responsible-gambling resource in Settings. Nuke never accepts wagers, deposits, or sportsbook credentials.",
            tags: ["Responsible play"],
            publishedAt: .now.addingTimeInterval(-2 * 60 * 60)
        )
    ]
}
