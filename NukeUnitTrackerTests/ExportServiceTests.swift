import Foundation
import XCTest
@testable import NukeUnitTracker

final class ExportServiceTests: XCTestCase {
    func testCSVIncludesCompleteBetDetailsAndEscapesText() throws {
        let placedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let bet = Bet(
            title: "Lakers, \"spread\"",
            sport: "NBA",
            league: "NBA",
            sportsbook: "Example Book",
            kind: .straight,
            oddsInput: -110,
            oddsFormat: .american,
            riskUnits: 1.5,
            result: .win,
            placedAt: placedAt,
            notes: "Tracked manually"
        )

        let url = try ExportService.writeCSV(bets: [bet])
        defer { try? FileManager.default.removeItem(at: url) }
        let csv = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(csv.hasPrefix("Placed Date,Settled Date,Title,Sport,League,Sportsbook,Type,Odds Format,Odds,Risk Units,Result,Net Units,Notes"))
        XCTAssertTrue(csv.contains("\"Lakers, \"\"spread\"\"\""))
        XCTAssertTrue(csv.contains("\"American\""))
        XCTAssertTrue(csv.contains("\"Tracked manually\""))
    }
}
