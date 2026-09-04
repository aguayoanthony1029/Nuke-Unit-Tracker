import XCTest
@testable import NukeUnitTracker

final class SlipRecognitionTests: XCTestCase {
    func testScannerParsesCommonSlipDetails() {
        let result = SlipRecognizer.parse(text: """
        FanDuel
        NFL Same Game Parlay
        Kansas City Chiefs @ Buffalo Bills
        Total Odds +275
        Stake $20.00
        """)

        XCTAssertEqual(result.sportsbook, "FanDuel")
        XCTAssertEqual(result.sport, "NFL")
        XCTAssertEqual(result.kind, .sameGameParlay)
        XCTAssertEqual(result.title, "Kansas City Chiefs @ Buffalo Bills")
        XCTAssertEqual(result.odds, 275)
        XCTAssertEqual(result.oddsFormat, .american)
        XCTAssertEqual(result.riskDollars, 20)
    }

    func testScannerRecognizesAddedSportsAndDecimalOdds() {
        let result = SlipRecognizer.parse(text: """
        bet365
        Table Tennis
        Total Odds: 1.91
        Wager: $12.50
        """)

        XCTAssertEqual(result.sportsbook, "bet365")
        XCTAssertEqual(result.sport, "Table Tennis")
        XCTAssertEqual(result.odds, 1.91)
        XCTAssertEqual(result.oddsFormat, .decimal)
        XCTAssertEqual(result.riskDollars, 12.5)
    }
}
