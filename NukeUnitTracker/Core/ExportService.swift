import Foundation

enum ExportService {
    static func writeCSV(bets: [Bet]) throws -> URL {
        var rows = ["Placed Date,Settled Date,Title,Sport,League,Sportsbook,Type,Odds Format,Odds,Risk Units,Result,Net Units,Notes"]
        let formatter = ISO8601DateFormatter()
        for bet in bets {
            let settledDate = bet.settledAt.map(formatter.string(from:)) ?? ""
            let oddsFormat = OddsFormat(rawValue: bet.oddsFormatRaw)?.label ?? bet.oddsFormatRaw
            let values = [
                formatter.string(from: bet.placedAt), settledDate, bet.title, bet.sport,
                bet.league, bet.sportsbook, bet.kind.label, oddsFormat, String(bet.oddsInput),
                String(bet.riskUnits), bet.result.label, String(bet.profitUnits), bet.notes
            ]
            rows.append(values.map(csvEscaped).joined(separator: ","))
        }
        let url = FileManager.default.temporaryDirectory.appending(path: "nuke-unit-tracker-export.csv")
        try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func csvEscaped(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" }
}
