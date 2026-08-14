import Foundation

enum ExportService {
    static func writeCSV(bets: [Bet]) throws -> URL {
        var rows = ["Date,Title,Sport,Sportsbook,Type,Odds,Risk Units,Result,Net Units"]
        let formatter = ISO8601DateFormatter()
        for bet in bets {
            let values = [formatter.string(from: bet.placedAt), bet.title, bet.sport, bet.sportsbook, bet.kind.label, String(bet.oddsInput), String(bet.riskUnits), bet.result.label, String(bet.profitUnits)]
            rows.append(values.map(csvEscaped).joined(separator: ","))
        }
        let url = FileManager.default.temporaryDirectory.appending(path: "nuke-unit-tracker-export.csv")
        try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func csvEscaped(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" }
}

