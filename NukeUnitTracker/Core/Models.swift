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

@Model
final class UserProfile {
    var id: UUID = UUID()
    var displayName: String = ""
    var unitValue: Double = 10
    var oddsFormatRaw: String = OddsFormat.american.rawValue
    var freePickAlertsEnabled: Bool = false
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 8
    var createdAt: Date = .now

    init(displayName: String, unitValue: Double) {
        self.displayName = displayName
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

