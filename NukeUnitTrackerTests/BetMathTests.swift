import XCTest
@testable import NukeUnitTracker

final class BetMathTests: XCTestCase {
    func testAmericanOddsConvertToDecimal() { XCTAssertEqual(OddsConverter.decimal(from: -110, format: .american), 1.90909, accuracy: 0.0001); XCTAssertEqual(OddsConverter.decimal(from: 150, format: .american), 2.5, accuracy: 0.0001) }
    func testWinningAndLosingUnits() {
        let win = Bet(title: "Test", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 1, result: .win, placedAt: .now, notes: "")
        let loss = Bet(title: "Test", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 2, result: .loss, placedAt: .now, notes: "")
        XCTAssertEqual(win.profitUnits, 0.90909, accuracy: 0.0001); XCTAssertEqual(loss.profitUnits, -2, accuracy: 0.0001)
    }
    func testPushReturnsNoProfit() { let bet = Bet(title: "Test", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 1, result: .push, placedAt: .now, notes: ""); XCTAssertEqual(bet.profitUnits, 0); XCTAssertEqual(bet.totalReturnUnits, 1) }
}

