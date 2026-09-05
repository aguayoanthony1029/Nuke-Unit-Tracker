import CoreGraphics
import Foundation
import ImageIO
import Vision

struct SlipScanResult: Equatable {
    var title: String?
    var selections: [String] = []
    var sport: String?
    var sportsbook: String?
    var kind: BetKind?
    var odds: Double?
    var oddsFormat: OddsFormat?
    var riskDollars: Double?

    var summary: String {
        var fields: [String] = []
        if sportsbook != nil { fields.append("sportsbook") }
        if sport != nil { fields.append("sport") }
        if kind != nil { fields.append("bet type") }
        if odds != nil { fields.append("odds") }
        if riskDollars != nil { fields.append("stake") }
        if title != nil { fields.append("selection") }

        guard !fields.isEmpty else {
            return "No bet details could be read. You can still enter the record manually."
        }
        return "Filled in \(fields.joined(separator: ", ")). Review every value before saving."
    }
}

enum SlipRecognitionError: LocalizedError {
    case unreadableImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "This image could not be read. Choose a clearer screenshot or photo."
        case .noTextFound:
            return "No readable text was found on this image."
        }
    }
}

enum SlipRecognizer {
    /// Reads a user-selected slip on device. The image and recognized text are never sent to a server.
    static func recognize(in imageData: Data) async throws -> SlipScanResult {
        try await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw SlipRecognitionError.unreadableImage
            }

            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
            let rawOrientation = properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1
            let orientation = CGImagePropertyOrientation(rawValue: rawOrientation) ?? .up

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
            try handler.perform([request])

            let lines = (request.results ?? []).compactMap { observation in
                observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let text = lines.filter { !$0.isEmpty }.joined(separator: "\n")
            guard !text.isEmpty else { throw SlipRecognitionError.noTextFound }
            return parse(text: text)
        }.value
    }

    static func parse(text: String) -> SlipScanResult {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let lowercasedText = text.lowercased()

        let sport: String?
        if containsAny(["college football", "ncaaf", "cfb"], in: lowercasedText) {
            sport = "College Football"
        } else if containsAny(["college baseball", "ncaa baseball"], in: lowercasedText) {
            sport = "College Baseball"
        } else if containsAny(["college basketball", "ncaab"], in: lowercasedText) {
            sport = "NCAAB"
        } else if containsAny(["table tennis", "ping pong"], in: lowercasedText) {
            sport = "Table Tennis"
        } else if lowercasedText.contains("tennis") {
            sport = "Tennis"
        } else if lowercasedText.contains("golf") {
            sport = "Golf"
        } else if lowercasedText.contains("nba") {
            sport = "NBA"
        } else if lowercasedText.contains("nfl") {
            sport = "NFL"
        } else if lowercasedText.contains("mlb") {
            sport = "MLB"
        } else if lowercasedText.contains("nhl") {
            sport = "NHL"
        } else if containsAny(["soccer", "football -"], in: lowercasedText) {
            sport = "Soccer"
        } else {
            sport = nil
        }

        let kind: BetKind?
        if containsAny(["same game parlay", "sgp"], in: lowercasedText) {
            kind = .sameGameParlay
        } else if lowercasedText.contains("parlay") {
            kind = .parlay
        } else if lowercasedText.contains("straight") {
            kind = .straight
        } else {
            kind = nil
        }

        let sportsbook = BetCatalog.sportsbooks.first { lowercasedText.contains($0.lowercased()) }
        let americanOdds = lastCapture(in: text, pattern: "(?<!\\d)[+-]\\d{3,4}(?!\\d)").flatMap(Double.init)
        let decimalOdds = firstCapture(in: text, pattern: "(?im)(?:total\\s*)?odds\\s*[:@]?\\s*(\\d{1,2}[\\.,]\\d{2,3})")
            .flatMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
        let odds = americanOdds ?? decimalOdds
        let oddsFormat: OddsFormat? = americanOdds != nil ? .american : (decimalOdds != nil ? .decimal : nil)

        let riskDollars = firstCapture(
            in: text,
            pattern: "(?im)(?:stake|wager|risk|bet\\s*amount|amount\\s*wagered)\\s*[:\\-]?\\s*\\$?\\s*([0-9][0-9,]*(?:\\.[0-9]{1,2})?)"
        ).flatMap { Double($0.replacingOccurrences(of: ",", with: "")) }

        let matchupTitle = lines.first { line in
            let lowercasedLine = line.lowercased()
            return line.count >= 5 &&
                (line.contains("@") || lowercasedLine.contains(" vs ") || lowercasedLine.contains(" v. ")) &&
                !lowercasedLine.contains("http")
        }

        // Sportsbooks often split a selection across separate lines, e.g.
        // "CeeDee Lamb" / "Over 67.5" / "Receiving Yards". Prefer that
        // useful selection to a generic matchup so the record needs less editing.
        let selections = selectionTitles(from: lines)
        let title = selections.first ?? matchupTitle

        return SlipScanResult(
            title: title,
            selections: selections,
            sport: sport,
            sportsbook: sportsbook,
            kind: kind,
            odds: odds,
            oddsFormat: oddsFormat,
            riskDollars: riskDollars
        )
    }

    /// Combines selections from several screenshots without repeating a leg that
    /// appears in an overlap between images. Keep the first spelling the user saw.
    static func mergeSelections(existing: [String], adding: [String]) -> (selections: [String], addedCount: Int, duplicatesSkipped: Int) {
        var merged = existing
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var addedCount = 0
        var duplicatesSkipped = 0

        for selection in adding {
            let trimmed = selection.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if merged.contains(where: { selectionsMatch($0, trimmed) }) {
                duplicatesSkipped += 1
            } else {
                merged.append(trimmed)
                addedCount += 1
            }
        }

        return (merged, addedCount, duplicatesSkipped)
    }

    private static func containsAny(_ terms: [String], in text: String) -> Bool {
        terms.contains { text.contains($0) }
    }

    private static func selectionTitles(from lines: [String]) -> [String] {
        let marketIndices = lines.indices.filter { index in
            guard looksLikeMarketLine(lines[index]) else { return false }

            // A stat label directly beneath an over/under is part of that same
            // selection, not a second leg. The same rule handles "-3.5" / "Spread".
            if index > lines.startIndex,
               looksLikeMarketLine(lines[index - 1]),
               isMarketContinuation(lines[index]) {
                return false
            }
            return true
        }

        return marketIndices.compactMap { selectionTitle(around: $0, in: lines) }
            .reduce(into: [String]()) { result, selection in
                guard !result.contains(where: { $0.caseInsensitiveCompare(selection) == .orderedSame }) else { return }
                result.append(selection)
            }
    }

    private static func selectionTitle(around marketIndex: Int, in lines: [String]) -> String? {
        let marketLine = lines[marketIndex]
        let context = lines[..<marketIndex]
            .reversed()
            .first(where: isSelectionContext)

        var parts: [String] = []
        if let context,
           !marketLine.localizedCaseInsensitiveContains(context),
           !marketLineContainsItsOwnSelection(marketLine) {
            parts.append(context)
        }

        // Milestone props can be displayed as "Player" / "3+" / "Made Threes".
        if marketIndex > lines.startIndex,
           isMilestoneValue(lines[marketIndex - 1]),
           !parts.contains(lines[marketIndex - 1]) {
            parts.append(lines[marketIndex - 1])
        }

        parts.append(marketLine)

        if marketIndex + 1 < lines.endIndex,
           isMarketContinuation(lines[marketIndex + 1]),
           !marketLine.localizedCaseInsensitiveContains(lines[marketIndex + 1]) {
            parts.append(lines[marketIndex + 1])
        }

        let uniqueParts = parts.reduce(into: [String]()) { result, part in
            guard !result.contains(where: { $0.caseInsensitiveCompare(part) == .orderedSame }) else { return }
            result.append(part)
        }
        let selection = uniqueParts.joined(separator: " — ")
        return selection.count >= 3 ? selection : nil
    }

    private static func looksLikeMarketLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        guard !isMetadataLine(line) else { return false }

        if marketTerms.contains(where: { lowercased.contains($0) }) {
            return true
        }

        // Team spreads are often shown as "Lakers -3.5" followed by "Spread".
        return lowercased.range(
            of: "(?<!\\d)[+-]\\d{1,2}(?:\\.\\d+)?(?!\\d)",
            options: .regularExpression
        ) != nil
    }

    private static func isMarketContinuation(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        guard !isMetadataLine(line) else { return false }
        return marketQualifierTerms.contains(where: { lowercased.contains($0) }) ||
            lowercased.range(of: "^(over|under)\\s*\\d", options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func isMilestoneValue(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines)
            .range(of: "^\\d{1,3}\\+$", options: .regularExpression) != nil
    }

    private static func marketLineContainsItsOwnSelection(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()

        // "Jayson Tatum Over 24.5 Points" and "Lakers -3.5 Spread" already
        // contain the player/team. Do not prepend the matchup above them.
        if let range = lowercased.range(of: "\\b(over|under|to win|moneyline|money line)\\b", options: .regularExpression) {
            let prefix = trimmed[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            return prefix.rangeOfCharacter(from: .letters) != nil &&
                !prefix.lowercased().contains("team total") &&
                !prefix.lowercased().contains("alternate")
        }

        return trimmed.range(
            of: "^.+\\s[+-]\\d{1,2}(?:\\.\\d+)?(?:\\s|$)",
            options: .regularExpression
        ) != nil
    }

    private static func isSelectionContext(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3,
              trimmed.rangeOfCharacter(from: .letters) != nil,
              !isMetadataLine(trimmed),
              !looksLikeMarketLine(trimmed) else {
            return false
        }
        return true
    }

    private static func isMetadataLine(_ line: String) -> Bool {
        let lowercased = line.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lowercased.isEmpty || BetCatalog.sportsbooks.contains(where: { $0.lowercased() == lowercased }) {
            return true
        }

        if lowercased.contains("parlay") || ["sgp", "straight", "single"].contains(lowercased) {
            return true
        }

        let metadataTerms = [
            "total odds", "odds", "stake", "wager", "risk", "payout", "potential", "balance",
            "bet slip", "betslip", "place bet", "cash out", "single", "live bet", "ticket"
        ]
        if metadataTerms.contains(where: { lowercased.contains($0) }) {
            return true
        }

        return ["nfl", "nba", "wnba", "mlb", "nhl", "ncaaf", "ncaab", "soccer", "tennis", "golf", "table tennis"]
            .contains(lowercased)
    }

    // These phrases cover common full-game, period, team, player, futures, and
    // specialty markets across football, baseball, basketball, hockey, soccer,
    // tennis, golf, table tennis, combat sports, racing, and esports slips.
    private static let marketTerms = [
        "same game parlay", "moneyline", "money line", "draw no bet", "double chance",
        "asian handicap", "point spread", "alternate spread", "alt spread", "spread",
        "alternate total", "alt total", "team total", "total", "over", "under",
        "correct score", "exact score", "method of victory", "winning margin", "race to",
        "first to score", "last to score", "first score", "next score", "first basket",
        "first touchdown", "anytime touchdown", "touchdown scorer", "first goalscorer",
        "anytime goalscorer", "last goalscorer", "next goalscorer", "both teams to score",
        "to qualify", "to advance", "to win", "make playoffs", "make the cut", "miss the cut",
        "top ", "outright", "head to head", "matchup", "winner", "champion", "mvp",
        "rookie of the year", "cy young", "defensive player", "sixth man", "most improved",
        "passing yards", "passing attempts", "pass completions", "passing touchdowns", "passing td",
        "interceptions thrown", "longest completion", "rushing yards", "rushing attempts",
        "rushing touchdowns", "longest rush", "receiving yards", "receptions", "receiving touchdowns",
        "longest reception", "field goals", "extra points", "sacks", "tackles", "tackles + assists",
        "quarterback hits", "fantasy points", "points + rebounds + assists", "points + rebounds",
        "points + assists", "rebounds + assists", "double double", "triple double", "made threes",
        "three pointers", "3-pointers", "3 pointers", "threes", "rebounds", "assists", "steals",
        "blocks", "turnovers", "minutes played", "points", "hits + runs + rbis", "total bases",
        "home runs", "runs batted", "rbis", "stolen bases", "walks", "pitcher strikeouts",
        "strikeouts", "outs recorded", "earned runs", "hits allowed", "walks allowed", "pitch count",
        "first inning", "no run first inning", "run line", "goals + assists + points", "shots on goal",
        "blocked shots", "goalie saves", "goals allowed", "power play points", "power play", "shutout",
        "goals", "shots", "saves", "corners", "cards", "yellow cards", "red cards", "fouls",
        "tackles won", "interceptions", "passes", "shots off target", "shots on target", "set winner",
        "set betting", "total games", "games handicap", "breaks of serve", "double faults", "aces",
        "birdies", "eagles", "bogeys", "strokes", "holes", "round score", "tournament score",
        "match winner", "game winner", "game handicap", "total points", "set handicap", "total sets",
        "significant strikes", "takedowns", "submission", "knockout", "decision", "round betting",
        "fight to start round", "fastest lap", "pole position", "podium", "driver matchup", "laps",
        "map winner", "total maps", "total rounds", "kills", "assists", "headshots"
    ]

    private static let marketQualifierTerms = [
        "yards", "yard", "attempts", "completions", "touchdowns", "touchdown", "receptions",
        "points", "rebounds", "assists", "steals", "blocks", "threes", "3-pointers", "turnovers",
        "hits", "runs", "rbis", "total bases", "home runs", "strikeouts", "outs", "earned runs",
        "shots", "goals", "saves", "corners", "cards", "fouls", "games", "sets", "aces",
        "double faults", "birdies", "eagles", "bogeys", "strokes", "holes", "takedowns", "strikes",
        "spread", "moneyline", "money line", "total", "winner", "handicap", "to score"
    ]

    private static func selectionsMatch(_ left: String, _ right: String) -> Bool {
        let leftKey = normalizedSelectionKey(left)
        let rightKey = normalizedSelectionKey(right)
        guard !leftKey.isEmpty, !rightKey.isEmpty else { return false }
        return leftKey == rightKey || leftKey.contains(rightKey) || rightKey.contains(leftKey)
    }

    private static func normalizedSelectionKey(_ selection: String) -> String {
        let normalizedWords = selection
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "money line", with: "moneyline")
            .replacingOccurrences(of: "3 pointers", with: "3pointers")
            .replacingOccurrences(of: "3-pointers", with: "3pointers")

        return normalizedWords.unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) || "+-.".unicodeScalars.contains($0) }
            .map(String.init)
            .joined()
    }

    private static func firstCapture(in text: String, pattern: String) -> String? {
        captures(in: text, pattern: pattern).first
    }

    private static func lastCapture(in text: String, pattern: String) -> String? {
        captures(in: text, pattern: pattern).last
    }

    private static func captures(in text: String, pattern: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return expression.matches(in: text, range: range).compactMap { match in
            let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
            guard let range = Range(captureRange, in: text) else { return nil }
            return String(text[range])
        }
    }
}
