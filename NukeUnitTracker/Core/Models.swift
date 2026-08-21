import Foundation
import SwiftData

enum OddsFormat: String, CaseIterable, Codable, Identifiable {
    case american, decimal
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum BetKind: String, CaseIterable, Codable, Identifiable {
    case straight, parlay, sameGameParlay
    var id: String { rawValue }
    var label: String {
        switch self { case .straight: "Straight"; case .parlay: "Parlay"; case .sameGameParlay: "Same-Game Parlay" }
    }
}

enum BetResult: String, CaseIterable, Codable, Identifiable {
    case pending, win, loss, push, void
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var tint: String { rawValue }
}

/// The only access distinction in the app. Tracking and free Nuke content are
/// always available; this value controls the optional editorial Vault.
enum PremiumAccessLevel: String, Codable, CaseIterable, Identifiable {
    case free
    case vip

    var id: String { rawValue }

    var label: String {
        switch self {
        case .free: "Free access"
        case .vip: "Nuke Vault verified"
        }
    }
}

enum EditorialVisibility: String, Codable, CaseIterable, Identifiable {
    case free
    case vip

    var id: String { rawValue }
}

enum EditorialKind: String, Codable, CaseIterable, Identifiable {
    case brief
    case analysis
    case news
    case pickCard = "pick_card"
    case announcement
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .brief: "Daily brief"
        case .analysis: "Nuke intel"
        case .news: "Newswire"
        case .pickCard: "Pick drop"
        case .announcement: "Signal alert"
        case .other: "Field note"
        }
    }

    var symbol: String {
        switch self {
        case .brief: "scope"
        case .analysis: "waveform.path.ecg"
        case .news: "newspaper.fill"
        case .pickCard: "target"
        case .announcement: "antenna.radiowaves.left.and.right"
        case .other: "bolt.fill"
        }
    }

    /// Publisher tooling can grow over time. Treat an unknown future kind as a
    /// neutral field note instead of failing the entire content response.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = EditorialKind(rawValue: try container.decode(String.self)) ?? .other
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

@Model
final class UserProfile {
    var id: UUID = UUID()
    var displayName: String = ""
    var unitValue: Double = 10
    var oddsFormatRaw: String = OddsFormat.american.rawValue
    var freePickAlertsEnabled: Bool = false
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 8
    /// Access is verified by the Nuke service after an optional Discord sign-in.
    /// It never gates the free tracker or free editorial feed.
    var premiumAccessRaw: String = PremiumAccessLevel.free.rawValue
    var discordUserID: String?
    var discordDisplayName: String?
    var premiumVerifiedAt: Date?
    var premiumExpiresAt: Date?
    var createdAt: Date = .now

    init(displayName: String, unitValue: Double) {
        self.displayName = displayName
        self.unitValue = unitValue
    }

    var oddsFormat: OddsFormat { OddsFormat(rawValue: oddsFormatRaw) ?? .american }
    var premiumAccess: PremiumAccessLevel { PremiumAccessLevel(rawValue: premiumAccessRaw) ?? .free }
    var hasActiveVIPAccess: Bool {
        premiumAccess == .vip && (premiumExpiresAt == nil || premiumExpiresAt! > .now)
    }
}

@Model
final class Bet {
    var id: UUID = UUID()
    var title: String = ""
    var sport: String = "Other"
    var league: String = ""
    var sportsbook: String = ""
    var kindRaw: String = BetKind.straight.rawValue
    var oddsDecimal: Double = 1.91
    var oddsInput: Double = -110
    var oddsFormatRaw: String = OddsFormat.american.rawValue
    var riskUnits: Double = 1
    var resultRaw: String = BetResult.pending.rawValue
    var placedAt: Date = .now
    var settledAt: Date?
    var notes: String = ""
    var eventIdentifier: String?
    var updatedAt: Date = .now

    init(title: String, sport: String, league: String, sportsbook: String, kind: BetKind, oddsInput: Double, oddsFormat: OddsFormat, riskUnits: Double, result: BetResult, placedAt: Date, notes: String) {
        self.title = title
        self.sport = sport
        self.league = league
        self.sportsbook = sportsbook
        self.kindRaw = kind.rawValue
        self.oddsInput = oddsInput
        self.oddsFormatRaw = oddsFormat.rawValue
        self.oddsDecimal = OddsConverter.decimal(from: oddsInput, format: oddsFormat)
        self.riskUnits = riskUnits
        self.resultRaw = result.rawValue
        self.placedAt = placedAt
        self.settledAt = result == .pending ? nil : placedAt
        self.notes = notes
    }

    var kind: BetKind { BetKind(rawValue: kindRaw) ?? .straight }
    var result: BetResult { BetResult(rawValue: resultRaw) ?? .pending }
    var profitUnits: Double { BetMath.profitUnits(for: self) }
    var totalReturnUnits: Double { result == .win ? riskUnits + profitUnits : (result == .push || result == .void ? riskUnits : 0) }
}

@Model
final class BetLeg {
    var id: UUID = UUID()
    var betID: UUID = UUID()
    var selection: String = ""
    var position: Int = 0
    init(betID: UUID, selection: String, position: Int) {
        self.betID = betID; self.selection = selection; self.position = position
    }
}

@Model
final class SlipAttachment {
    var id: UUID = UUID()
    var betID: UUID = UUID()
    var localRelativePath: String = ""
    var cloudRecordName: String?
    var createdAt: Date = .now
    init(betID: UUID, localRelativePath: String) {
        self.betID = betID; self.localRelativePath = localRelativePath
    }
}

struct FreePick: Codable, Identifiable, Equatable {
    let id: String
    let content: String
    let imageURLs: [URL]
    let postedAt: Date
    let editedAt: Date?
    let discordURL: URL?
}

/// A single editorially published selection. These may be added to a user's
/// private Tail Board; they never open, populate, or place a sportsbook wager.
struct NukePick: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let label: String
    let sport: String
    let league: String?
    let event: String
    let selection: String
    let market: String?
    let line: String?
    let oddsAmerican: Double?
    let oddsDecimal: Double?
    let bookmaker: String?
    let startsAt: Date?
    let deepLinkURL: URL?
    /// Present on the flattened Tail Board endpoint. It lets the app keep two
    /// otherwise-identical selections from different editorial posts distinct.
    var contentID: String? = nil

    var displayOdds: String {
        if let oddsAmerican { return String(format: "%+.0f", oddsAmerican) }
        if let oddsDecimal { return String(format: "%.2f", oddsDecimal) }
        return "Odds pending"
    }

    var normalizedDecimalOdds: Double? {
        if let oddsDecimal, oddsDecimal > 1 { return oddsDecimal }
        if let oddsAmerican, oddsAmerican != 0 {
            return OddsConverter.decimal(from: oddsAmerican, format: .american)
        }
        return nil
    }

    var boardTitle: String {
        [event, selection].filter { !$0.isEmpty }.joined(separator: " - ")
    }

    var marketLine: String {
        [market, line].compactMap { value in
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return value
        }.joined(separator: " ")
    }
}

/// The publication unit returned by the Nuke content service. Optional fields
/// keep old Discord-relay content and new editorial content compatible.
struct NukeEditorialPost: Codable, Identifiable, Equatable {
    let id: String
    let slug: String?
    let visibility: EditorialVisibility
    let kind: EditorialKind
    let title: String
    let summary: String
    let body: String
    let heroImageURL: URL?
    let imageURLs: [URL]
    let tags: [String]
    let picks: [NukePick]
    let sourceURL: URL?
    let publishedAt: Date
    let pinnedAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, slug, visibility, kind, title, summary, body, heroImageURL, imageURLs, tags, picks, sourceURL, publishedAt, pinnedAt, updatedAt
    }

    init(
        id: String,
        slug: String? = nil,
        visibility: EditorialVisibility,
        kind: EditorialKind,
        title: String,
        summary: String,
        body: String,
        heroImageURL: URL? = nil,
        imageURLs: [URL] = [],
        tags: [String] = [],
        picks: [NukePick] = [],
        sourceURL: URL? = nil,
        publishedAt: Date = .now,
        pinnedAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.slug = slug
        self.visibility = visibility
        self.kind = kind
        self.title = title
        self.summary = summary
        self.body = body
        self.heroImageURL = heroImageURL
        self.imageURLs = imageURLs
        self.tags = tags
        self.picks = picks
        self.sourceURL = sourceURL
        self.publishedAt = publishedAt
        self.pinnedAt = pinnedAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        visibility = try container.decodeIfPresent(EditorialVisibility.self, forKey: .visibility) ?? .free
        kind = try container.decodeIfPresent(EditorialKind.self, forKey: .kind) ?? .other
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Nuke update"
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        heroImageURL = try container.decodeIfPresent(URL.self, forKey: .heroImageURL)
        imageURLs = try container.decodeIfPresent([URL].self, forKey: .imageURLs) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        picks = try container.decodeIfPresent([NukePick].self, forKey: .picks) ?? []
        sourceURL = try container.decodeIfPresent(URL.self, forKey: .sourceURL)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt) ?? .now
        pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

struct PremiumEntitlement: Codable, Equatable {
    let authenticated: Bool
    let discordUserID: String?
    let access: PremiumAccessLevel
    let expiresAt: Date?
    let verifiedAt: Date?
}

/// A private, local saved selection. It is intentionally separate from Bet:
/// adding a published pick to a Tail Board does not record or imply a wager.
@Model
final class TailBoardItem {
    var id: UUID = UUID()
    var sourcePickID: String = ""
    var sourcePostID: String?
    var label: String = ""
    var sport: String = "Other"
    var league: String?
    var event: String = ""
    var selection: String = ""
    var market: String?
    var line: String?
    var oddsAmerican: Double?
    var oddsDecimal: Double?
    var bookmaker: String?
    var startsAt: Date?
    var isInBasket: Bool = true
    var createdAt: Date = .now
    var updatedAt: Date = .now

    init(
        pick: NukePick,
        sourcePostID: String? = nil,
        sourcePickID: String? = nil,
        isInBasket: Bool = true
    ) {
        self.sourcePickID = sourcePickID ?? pick.id
        self.sourcePostID = sourcePostID ?? pick.contentID
        self.label = pick.label
        self.sport = pick.sport
        self.league = pick.league
        self.event = pick.event
        self.selection = pick.selection
        self.market = pick.market
        self.line = pick.line
        self.oddsAmerican = pick.oddsAmerican
        self.oddsDecimal = pick.normalizedDecimalOdds
        self.bookmaker = pick.bookmaker
        self.startsAt = pick.startsAt
        self.isInBasket = isInBasket
    }

    var displayOdds: String {
        if let oddsAmerican { return String(format: "%+.0f", oddsAmerican) }
        if let oddsDecimal { return String(format: "%.2f", oddsDecimal) }
        return "Odds pending"
    }

    var cleanSelectionLine: String {
        [selection, line].compactMap { value in
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return value
        }.joined(separator: " ")
    }
}
