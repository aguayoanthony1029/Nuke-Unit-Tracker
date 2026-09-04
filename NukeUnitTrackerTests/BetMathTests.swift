import XCTest
@testable import NukeUnitTracker

final class BetMathTests: XCTestCase {
    func testAmericanOddsConvertToDecimal() { XCTAssertEqual(OddsConverter.decimal(from: -110, format: .american), 1.90909, accuracy: 0.0001); XCTAssertEqual(OddsConverter.decimal(from: 150, format: .american), 2.5, accuracy: 0.0001) }
    func testOddsValidationRejectsInvalidSportsbookValues() {
        XCTAssertTrue(OddsConverter.isValid(-110, format: .american))
        XCTAssertTrue(OddsConverter.isValid(150, format: .american))
        XCTAssertFalse(OddsConverter.isValid(0, format: .american))
        XCTAssertFalse(OddsConverter.isValid(99, format: .american))
        XCTAssertFalse(OddsConverter.isValid(-99, format: .american))
        XCTAssertTrue(OddsConverter.isValid(1.91, format: .decimal))
        XCTAssertFalse(OddsConverter.isValid(1, format: .decimal))
        XCTAssertFalse(OddsConverter.isValid(.infinity, format: .decimal))
    }
    func testWinningAndLosingUnits() {
        let win = Bet(title: "Test", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 1, result: .win, placedAt: .now, notes: "")
        let loss = Bet(title: "Test", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 2, result: .loss, placedAt: .now, notes: "")
        XCTAssertEqual(win.profitUnits, 0.90909, accuracy: 0.0001); XCTAssertEqual(loss.profitUnits, -2, accuracy: 0.0001)
    }
    func testPushReturnsNoProfit() { let bet = Bet(title: "Test", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 1, result: .push, placedAt: .now, notes: ""); XCTAssertEqual(bet.profitUnits, 0); XCTAssertEqual(bet.totalReturnUnits, 1) }
    func testSummarySeparatesPendingExposureFromSettledRecord() {
        let win = Bet(title: "Win", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 1, result: .win, placedAt: .now, notes: "")
        let loss = Bet(title: "Loss", sport: "NFL", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 2, result: .loss, placedAt: .now.addingTimeInterval(-60), notes: "")
        let pending = Bet(title: "Pending", sport: "MLB", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 1.5, result: .pending, placedAt: .now, notes: "")

        let summary = StatisticsService.summary(for: [win, loss, pending])

        XCTAssertEqual(summary.record, Record(wins: 1, losses: 1, pushes: 0))
        XCTAssertEqual(summary.pendingExposure, 1.5, accuracy: 0.0001)
        XCTAssertEqual(summary.netUnits, -1.090909, accuracy: 0.0001)
        XCTAssertEqual(summary.roi, -1.090909 / 3, accuracy: 0.0001)
    }

    func testPushDoesNotBreakDecisionStreak() {
        let win1 = Bet(title: "Win 1", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 1, result: .win, placedAt: .now.addingTimeInterval(-120), notes: "")
        let win2 = Bet(title: "Win 2", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 1, result: .win, placedAt: .now.addingTimeInterval(-60), notes: "")
        let push = Bet(title: "Push", sport: "NBA", league: "", sportsbook: "", kind: .straight, oddsInput: -110, oddsFormat: .american, riskUnits: 1, result: .push, placedAt: .now, notes: "")

        XCTAssertEqual(StatisticsService.summary(for: [win1, win2, push]).streak, "W2")
    }
}
