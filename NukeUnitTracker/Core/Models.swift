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
}

@Model
final class UserProfile {
    var id: UUID = UUID()
    // These legacy fields stay in the model so upgrades from earlier builds keep
    // their existing records. The current interface intentionally does not use them.
    var displayName: String = ""
    var unitValue: Double = 10
    var oddsFormatRaw: String = OddsFormat.american.rawValue
    var freePickAlertsEnabled: Bool = false
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 8
    var premiumAccessRaw: String = "free"
    var discordUserID: String?
    var discordDisplayName: String?
    var premiumVerifiedAt: Date?
    var premiumExpiresAt: Date?
    var createdAt: Date = Date.now

    init(unitValue: Double) {
        self.unitValue = unitValue
    }

    var oddsFormat: OddsFormat { OddsFormat(rawValue: oddsFormatRaw) ?? .american }
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
    var placedAt: Date = Date.now
    var settledAt: Date?
    var notes: String = ""
    // Kept for on-device schema compatibility with earlier app builds.
    var eventIdentifier: String?
    var updatedAt: Date = Date.now

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
    // Previous builds could sync slip assets privately. Retaining this metadata
    // prevents an update from discarding an existing attachment record.
    var cloudRecordName: String?
    var createdAt: Date = Date.now
    init(betID: UUID, localRelativePath: String) {
        self.betID = betID; self.localRelativePath = localRelativePath
    }
}

/// This model is no longer shown in the app, but it remains in storage so an
/// update from an earlier build never has to remove a user's saved records.
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
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(sourcePickID: String = "") {
        self.sourcePickID = sourcePickID
    }
}
