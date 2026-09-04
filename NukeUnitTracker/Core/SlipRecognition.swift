import CoreGraphics
import Foundation
import ImageIO
import Vision

struct SlipScanResult: Equatable {
    var title: String?
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

        let title = lines.first { line in
            let lowercasedLine = line.lowercased()
            return line.count >= 5 &&
                (line.contains("@") || lowercasedLine.contains(" vs ") || lowercasedLine.contains(" v. ")) &&
                !lowercasedLine.contains("http")
        }

        return SlipScanResult(
            title: title,
            sport: sport,
            sportsbook: sportsbook,
            kind: kind,
            odds: odds,
            oddsFormat: oddsFormat,
            riskDollars: riskDollars
        )
    }

    private static func containsAny(_ terms: [String], in text: String) -> Bool {
        terms.contains { text.contains($0) }
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
